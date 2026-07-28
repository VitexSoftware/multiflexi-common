#!/bin/bash
# Deep-verifies dependency manifests for locally cloned MultiFlexi repos under
# the given workspace root. Unlike gh-manifest-scan.sh (file-presence via the
# GitHub API), this checks whether lockfiles are actually *committed*
# (git ls-files, not just present on disk) and whether any SBOM/dependency
# scanning config already exists.
#
# Usage: local-inventory.sh [workspace-root]
# Default workspace-root: /home/vitex/Projects/Multi
#
# Output: CSV to stdout with columns:
#   repo,remote,in_scope,ecosystems,composer_lock_committed,package_lock_committed,
#   dependabot,renovate
#
# Safe to re-run: read-only, writes nothing to any repo.

set -o pipefail

ROOT="${1:-/home/vitex/Projects/Multi}"

# Repos explicitly out of scope (see plan: no remote / foreign remote / Debian-only).
EXCLUDE_NO_REMOTE=(multifymfo-old MultiSymfo)
EXCLUDE_FOREIGN_REMOTE=(zabbix-agent2-plugin-multiflexi)
EXCLUDE_DEBIAN_ONLY=(jenkins-configuration jenkins-multiflexi MultiFlexi-cz MultiFlexi-publish multiflexi-buildimages multiflexi-mtr)

is_in() {
    local needle="$1"; shift
    for x in "$@"; do [ "$x" = "$needle" ] && return 0; done
    return 1
}

echo "repo,remote,in_scope,ecosystems,composer_lock_committed,package_lock_committed,dependabot,renovate"

for dir in "$ROOT"/*/; do
    repo=$(basename "$dir")
    [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || continue

    remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null)

    scope="yes"
    reason=""
    if [ -z "$remote" ] || is_in "$repo" "${EXCLUDE_NO_REMOTE[@]}"; then
        scope="no"; reason="no-remote"
    elif [[ "$remote" == *"git.zabbix.com"* ]] || is_in "$repo" "${EXCLUDE_FOREIGN_REMOTE[@]}"; then
        scope="no"; reason="foreign-remote"
    elif is_in "$repo" "${EXCLUDE_DEBIAN_ONLY[@]}"; then
        scope="no"; reason="debian-only-no-manifest"
    fi
    [ -n "$reason" ] && scope="no:$reason"

    files=$(git -C "$dir" ls-files 2>/dev/null)

    ecosystems=""
    echo "$files" | grep -qE '(^|/)composer\.json$' && ecosystems="${ecosystems}php;"
    echo "$files" | grep -qE '(^|/)package\.json$' && ecosystems="${ecosystems}npm;"
    echo "$files" | grep -qE '(^|/)(pyproject\.toml|requirements\.txt|setup\.py)$' && ecosystems="${ecosystems}python;"
    echo "$files" | grep -qE '(^|/)go\.mod$' && ecosystems="${ecosystems}go;"
    echo "$files" | grep -qE '(^|/)pom\.xml$' && ecosystems="${ecosystems}java;"
    [ -z "$ecosystems" ] && ecosystems="none"

    composer_lock=$(echo "$files" | grep -qE '(^|/)composer\.lock$' && echo yes || echo no)
    package_lock=$(echo "$files" | grep -qE '(^|/)package-lock\.json$' && echo yes || echo no)
    dependabot=$(echo "$files" | grep -qE '\.github/dependabot\.ya?ml$' && echo yes || echo no)
    renovate=$(echo "$files" | grep -qE '(^|/)renovate\.json5?$' && echo yes || echo no)

    echo "$repo,$remote,$scope,$ecosystems,$composer_lock,$package_lock,$dependabot,$renovate"
done
