#!/bin/bash
# Batch driver: runs generate-sbom.sh over every in-scope repo under the
# workspace root (excludes repos with no remote, a foreign remote, or no
# app-level dependency manifest - see local-inventory.sh for the same list).
#
# Usage: generate-sbom-all.sh [workspace-root] [output-dir]
#
# Idempotent: delegates to generate-sbom.sh per repo, which always
# overwrites its deterministic output path.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-/home/vitex/Projects/Multi}"
OUTPUT_DIR="${2:-$SCRIPT_DIR/sbom}"
export PATH="$PATH:$HOME/go/bin"

EXCLUDE=(multifymfo-old MultiSymfo zabbix-agent2-plugin-multiflexi \
         jenkins-configuration jenkins-multiflexi MultiFlexi-cz \
         MultiFlexi-publish multiflexi-buildimages multiflexi-mtr)

is_excluded() {
    local needle="$1"
    for x in "${EXCLUDE[@]}"; do [ "$x" = "$needle" ] && return 0; done
    return 1
}

mkdir -p "$OUTPUT_DIR"
GAP_CSV="$SCRIPT_DIR/gap-summary.csv"
echo "repo,in_scope,lockfile_committed,sbom_generated_by_audit,notes" > "$GAP_CSV"

for dir in "$ROOT"/*/; do
    repo=$(basename "$dir")
    [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || continue
    if is_excluded "$repo"; then
        echo "repo,no,n/a,no,excluded (see local-inventory.sh reason)" | sed "s/^repo/$repo/" >> "$GAP_CSV"
        continue
    fi

    log=$("$SCRIPT_DIR/generate-sbom.sh" "$dir" "$OUTPUT_DIR" 2>&1)
    echo "$log"

    generated=$(ls "$OUTPUT_DIR/$repo".*.cdx.json 2>/dev/null | wc -l)
    lockfile="no"
    echo "$log" | grep -q "unlocked/approximate\|no package-lock.json committed\|no requirements.txt" && lockfile="no"
    [ "$generated" -gt 0 ] && ! echo "$log" | grep -q "unlocked/approximate\|no package-lock.json committed" && lockfile="yes"

    if [ "$generated" -gt 0 ]; then
        sbom_generated="yes ($generated file(s))"
    else
        sbom_generated="no"
    fi

    notes=$(echo "$log" | grep '^WARN' | tr '\n' ';' | sed 's/,/;/g')
    echo "$repo,yes,$lockfile,\"$sbom_generated\",\"$notes\"" >> "$GAP_CSV"
done

echo ""
echo "Gap summary written to $GAP_CSV"
