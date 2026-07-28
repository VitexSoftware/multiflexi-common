# Security Policy

## Supported Versions

Security fixes are provided for the current stable release only, in line
with the Debian/Ubuntu platform-support policy (see
`multiflexi-doc-en/source/platform-support.rst`).

| Version | Supported |
| ------- | --------- |
| Latest release (Debian 13 / Trixie packages) | :white_check_mark: |
| Older releases | :x: |

## Reporting a Vulnerability

Please report suspected security vulnerabilities privately. **Do not open a
public GitHub issue for security reports.**

Use GitHub Security Advisories: open the **Security** tab on the relevant
repository and select **"Report a vulnerability"**. This keeps the report
private to maintainers until a fix is ready.

We aim to acknowledge new reports within **3 business days**.

## Scope

MultiFlexi is a multi-repository project (job scheduling/orchestration
platform for the Czech accounting/ERP niche). This policy covers the core
components under the `VitexSoftware` GitHub organization:

- `multiflexi-server`
- `multiflexi-web5`
- `multiflexi-scheduler`
- `multiflexi-executor`
- `multiflexi-cli`
- `multiflexi-database`
- `php-vitexsoftware-multiflexi-core`

...and related app/credential-type integration packages built on these
components.

## Disclosure Policy

We follow coordinated disclosure: once a report is confirmed, we aim to
release a fix before any public disclosure of the vulnerability's details.
For most issues this targets a 90-day window from confirmation to fix
release, extended by mutual agreement for cases needing more time (e.g.
coordinating with a third-party dependency maintainer).

## Software Bill of Materials (SBOM)

Dependency inventories for MultiFlexi components are generated as CycloneDX
SBOMs — see the SBOM process documentation for the current format, tooling,
and coverage: `sbom-process.rst` in `multiflexi-doc-en`
(https://multiflexi.eu once published). This supports vulnerability
identification in third-party dependencies, independent of any specific
compliance framework.
