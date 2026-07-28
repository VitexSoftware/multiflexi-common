# SBOM tooling

Scripts for generating CycloneDX SBOMs across MultiFlexi repositories and
inventorying dependency manifests, produced by the 2026-07 CRA/SBOM
compliance audit. See `source/sbom-process.rst` and
`_audit/sbom-cra-audit-2026-07.md` in `multiflexi-doc-en` for the full
process writeup and audit findings.

## Scripts

- `gh-manifest-scan.sh [org ...]` — scans all repos in the given GitHub
  orgs (default: VitexSoftware, Spoje-NET) for dependency manifest files via
  the GitHub API, no cloning required. Requires an authenticated `gh` CLI.
- `local-inventory.sh [workspace-root]` — deep-verifies lockfile-committed
  status and existing SBOM/Dependabot/Renovate tooling for locally cloned
  repos (default workspace root: `/home/vitex/Projects/Multi`).
- `generate-sbom.sh <repo-path> [output-dir]` — generates a CycloneDX SBOM
  for a single repo, dispatching per detected ecosystem. Idempotent.
- `generate-sbom-all.sh [workspace-root] [output-dir]` — batch driver over
  all in-scope repos, also writes a gap-summary CSV.
- `sbom-workflow.yml.example` — draft GitHub Actions template. **Not wired
  into any repo's CI** — adopting it per-repo is a separate decision.

All scripts are safe to re-run: outputs are deterministic and always
overwritten in place, never appended to or duplicated.

## One-time setup

`generate-sbom.sh` dispatches to a CycloneDX generator per ecosystem. None
of these are required to run any single generator — only the ones for
ecosystems you actually need to cover.

```bash
# PHP — installed into an isolated COMPOSER_HOME so it never touches a
# target project's own composer.json/composer.lock.
mkdir -p .tools/composer-home
COMPOSER_HOME="$(pwd)/.tools/composer-home" composer global config --no-interaction allow-plugins.cyclonedx/cyclonedx-php-composer true
COMPOSER_HOME="$(pwd)/.tools/composer-home" composer global require --no-interaction cyclonedx/cyclonedx-php-composer

# Python
pipx install cyclonedx-bom

# npm
npm install -g @cyclonedx/cyclonedx-npm

# Go
go install github.com/CycloneDX/cyclonedx-gomod/cmd/cyclonedx-gomod@latest
# ensure $HOME/go/bin is on PATH

# Java/Maven — no separate install; cyclonedx-maven-plugin is resolved by
# Maven on first invocation.
```

`.tools/` (the isolated Composer home) and generated output (`sbom/`,
`*.csv`) are gitignored — they're local caches / regenerable point-in-time
artifacts, not source.

## Known gaps (see the audit doc for the full list)

- `cyclonedx-py` has no direct PEP 621 (`pyproject.toml`-only) support —
  repos without a `requirements.txt` are not covered.
- `cyclonedx-php-composer` requires a `composer.lock` present on disk; it
  cannot generate from `composer.json` version ranges alone.
- `cyclonedx-npm` requires a committed `package-lock.json` or an installed
  `node_modules`.
