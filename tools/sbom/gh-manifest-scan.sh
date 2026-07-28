#!/bin/bash
# Scans all repos in the given GitHub orgs for dependency-manifest files,
# without cloning. Requires an authenticated `gh` CLI.
#
# Usage: gh-manifest-scan.sh [org ...]
# Default orgs: VitexSoftware Spoje-NET
#
# Output: CSV to stdout with columns:
#   org,repo,archived,default_branch,composer_json,composer_lock,package_json,
#   package_lock_json,pyproject_toml,requirements_txt,go_mod,pom_xml,
#   debian_control,dockerfile
#
# Safe to re-run: it only reads from the GitHub API, writes nothing to any repo.

set -o pipefail

ORGS=("$@")
if [ ${#ORGS[@]} -eq 0 ]; then
    ORGS=(VitexSoftware Spoje-NET)
fi

echo "org,repo,archived,default_branch,composer_json,composer_lock,package_json,package_lock_json,pyproject_toml,requirements_txt,go_mod,pom_xml,debian_control,dockerfile"

for org in "${ORGS[@]}"; do
    repo_json=$(gh repo list "$org" --limit 500 --json name,isArchived,defaultBranchRef,isFork)
    echo "$repo_json" | jq -c '.[]' | while read -r repo; do
        name=$(echo "$repo" | jq -r '.name')
        archived=$(echo "$repo" | jq -r '.isArchived')
        branch=$(echo "$repo" | jq -r '.defaultBranchRef.name // "main"')

        # One call per repo: full recursive file tree, then grep locally.
        # Falls back to empty tree (all columns "no") if the API call fails
        # (e.g. empty repo, no default branch) rather than aborting the scan.
        tree=$(gh api "repos/$org/$name/git/trees/$branch?recursive=1" --jq '.tree[]?.path' 2>/dev/null)

        has() { echo "$tree" | grep -qE "$1" && echo "yes" || echo "no"; }

        composer_json=$(has '(^|/)composer\.json$')
        composer_lock=$(has '(^|/)composer\.lock$')
        package_json=$(has '(^|/)package\.json$')
        package_lock_json=$(has '(^|/)package-lock\.json$')
        pyproject_toml=$(has '(^|/)pyproject\.toml$')
        requirements_txt=$(has '(^|/)requirements\.txt$')
        go_mod=$(has '(^|/)go\.mod$')
        pom_xml=$(has '(^|/)pom\.xml$')
        debian_control=$(has '(^|/)debian/control$')
        dockerfile=$(has '(^|/)Dockerfile[^/]*$')

        echo "$org,$name,$archived,$branch,$composer_json,$composer_lock,$package_json,$package_lock_json,$pyproject_toml,$requirements_txt,$go_mod,$pom_xml,$debian_control,$dockerfile"
    done
done
