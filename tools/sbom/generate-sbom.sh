#!/bin/bash
# Generates a CycloneDX SBOM for a single repo, dispatching to the matching
# generator per detected ecosystem (a repo can match more than one, e.g.
# php+npm -> two output files).
#
# Usage: generate-sbom.sh <repo-path> [output-dir]
# Default output-dir: <script-dir>/sbom
#
# Idempotent: output filenames are deterministic and always overwritten in
# place. If a required tool is missing, that ecosystem is skipped with a
# clear stderr warning rather than failing the whole run.
#
# Requires the tooling installed by the spike in this directory:
#   - PHP:    isolated COMPOSER_HOME at ./.tools/composer-home
#             (cyclonedx/cyclonedx-php-composer installed globally there)
#   - Python: cyclonedx-py (pipx install cyclonedx-bom)
#   - npm:    cyclonedx-npm (npm install -g @cyclonedx/cyclonedx-npm)
#   - Go:     cyclonedx-gomod (go install .../cyclonedx-gomod/cmd/cyclonedx-gomod@latest)
#   - Java:   mvn (cyclonedx-maven-plugin resolved on demand, no separate install)

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSER_HOME_ISOLATED="$SCRIPT_DIR/.tools/composer-home"

REPO_PATH="$1"
OUTPUT_DIR="${2:-$SCRIPT_DIR/sbom}"

if [ -z "$REPO_PATH" ] || [ ! -d "$REPO_PATH" ]; then
    echo "Usage: $0 <repo-path> [output-dir]" >&2
    exit 1
fi

REPO_NAME="$(basename "$REPO_PATH")"
mkdir -p "$OUTPUT_DIR"

warn() { echo "WARN [$REPO_NAME]: $1" >&2; }
ok()   { echo "OK   [$REPO_NAME]: $1"; }

GENERATED_ANY="no"

# --- PHP / Composer -----------------------------------------------------
# cyclonedx-php-composer requires a composer.lock present on disk (it cannot
# generate from composer.json's version ranges alone) - skip cleanly rather
# than let the underlying tool fail with a generic error.
if [ -f "$REPO_PATH/composer.json" ] && [ ! -f "$REPO_PATH/composer.lock" ]; then
    warn "composer.json present but no composer.lock on disk - cyclonedx-php-composer cannot generate without one, skipping (this is a gap: run 'composer install/update' and commit the lockfile to enable SBOM generation)"
elif [ -f "$REPO_PATH/composer.json" ]; then
    if command -v composer >/dev/null 2>&1 && [ -d "$COMPOSER_HOME_ISOLATED" ]; then
        out="$OUTPUT_DIR/$REPO_NAME.php.cdx.json"
        approx=""
        git -C "$REPO_PATH" ls-files --error-unmatch composer.lock >/dev/null 2>&1 || approx=" (composer.lock present on disk but not committed to git - output reflects the local, possibly stale lockfile)"
        if COMPOSER_HOME="$COMPOSER_HOME_ISOLATED" composer --working-dir="$REPO_PATH" CycloneDX:make-sbom \
            --output-format=JSON --output-file="$out" >/dev/null 2>&1; then
            ok "php sbom written to $out$approx"
            GENERATED_ANY="yes"
        else
            warn "cyclonedx-php-composer failed on $REPO_PATH"
        fi
    else
        warn "composer or isolated COMPOSER_HOME not found, skipping PHP ecosystem"
    fi
fi

# --- Python ---------------------------------------------------------------
if [ -f "$REPO_PATH/requirements.txt" ] || [ -f "$REPO_PATH/pyproject.toml" ]; then
    if command -v cyclonedx-py >/dev/null 2>&1; then
        out="$OUTPUT_DIR/$REPO_NAME.python.cdx.json"
        if [ -f "$REPO_PATH/requirements.txt" ]; then
            if (cd "$REPO_PATH" && cyclonedx-py requirements requirements.txt -o "$out" --output-format json) >/dev/null 2>&1; then
                ok "python sbom written to $out (from requirements.txt, versions may be unpinned/approximate)"
                GENERATED_ANY="yes"
            else
                warn "cyclonedx-py failed on $REPO_PATH/requirements.txt"
            fi
        else
            warn "pyproject.toml present but no requirements.txt - cyclonedx-py has no direct PEP 621 support, skipping (approximate generation not attempted)"
        fi
    else
        warn "cyclonedx-py not found, skipping Python ecosystem"
    fi
fi

# --- npm --------------------------------------------------------------
if [ -f "$REPO_PATH/package.json" ]; then
    if command -v cyclonedx-npm >/dev/null 2>&1; then
        out="$OUTPUT_DIR/$REPO_NAME.npm.cdx.json"
        if [ -f "$REPO_PATH/package-lock.json" ]; then
            if (cd "$REPO_PATH" && cyclonedx-npm --output-format json --output-file "$out") >/dev/null 2>&1; then
                ok "npm sbom written to $out"
                GENERATED_ANY="yes"
            else
                warn "cyclonedx-npm failed on $REPO_PATH"
            fi
        else
            warn "no package-lock.json committed, cyclonedx-npm requires a lockfile or node_modules - skipping (this is a gap: add and commit a lockfile to enable SBOM generation)"
        fi
    else
        warn "cyclonedx-npm not found, skipping npm ecosystem"
    fi
fi

# --- Go ---------------------------------------------------------------
if [ -f "$REPO_PATH/go.mod" ]; then
    GOMOD_BIN="cyclonedx-gomod"
    command -v "$GOMOD_BIN" >/dev/null 2>&1 || GOMOD_BIN="$HOME/go/bin/cyclonedx-gomod"
    if [ -x "$GOMOD_BIN" ] || command -v "$GOMOD_BIN" >/dev/null 2>&1; then
        out="$OUTPUT_DIR/$REPO_NAME.go.cdx.json"
        if (cd "$REPO_PATH" && "$GOMOD_BIN" mod -json -output "$out") >/dev/null 2>&1; then
            ok "go sbom written to $out"
            GENERATED_ANY="yes"
        else
            warn "cyclonedx-gomod failed on $REPO_PATH"
        fi
    else
        warn "cyclonedx-gomod not found, skipping Go ecosystem"
    fi
fi

# --- Java / Maven -------------------------------------------------------
if [ -f "$REPO_PATH/pom.xml" ]; then
    if command -v mvn >/dev/null 2>&1; then
        outname="$REPO_NAME.java.cdx"
        if mvn -q -f "$REPO_PATH/pom.xml" org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom \
            -DoutputFormat=json -DoutputName="$outname" >/dev/null 2>&1; then
            if [ -f "$REPO_PATH/target/$outname.json" ]; then
                mv "$REPO_PATH/target/$outname.json" "$OUTPUT_DIR/$outname.json"
                rmdir --ignore-fail-on-non-empty "$REPO_PATH/target" 2>/dev/null
                ok "java sbom written to $OUTPUT_DIR/$outname.json"
                GENERATED_ANY="yes"
            else
                warn "cyclonedx-maven-plugin ran but expected output not found"
            fi
        else
            warn "cyclonedx-maven-plugin failed on $REPO_PATH"
        fi
    else
        warn "mvn not found, skipping Java ecosystem"
    fi
fi

if [ "$GENERATED_ANY" = "no" ]; then
    warn "no supported ecosystem manifest found or all generations skipped"
    exit 0
fi
