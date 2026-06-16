# MultiFlexi Common — Development Guidelines for GitHub Copilot

<!-- Custom workspace instructions for GitHub Copilot to ensure consistent code quality and project standards -->

## 🗂️ Repository Purpose

This repository (`multiflexi-common`) contains **shared assets and common documentation** for the MultiFlexi project ecosystem. It does **not** contain PHP application code.

For related code, see:

| Repository | Purpose |
|---|---|
| [multiflexi-doc-en](https://github.com/VitexSoftware/multiflexi-doc-en) | English user-facing documentation |
| [multiflexi-web](https://github.com/VitexSoftware/multiflexi-web) | Web interface / UI code |
| [php-vitexsoftware-multiflexi-core](https://github.com/VitexSoftware/php-vitexsoftware-multiflexi-core) | Core PHP library |
| [multiflexi-server](https://github.com/VitexSoftware/multiflexi-server) | REST API backend |
| [multiflexi-zabbix](https://github.com/VitexSoftware/multiflexi-zabbix) | Zabbix LLD scripts and monitoring templates |

> Do **not** add end-user documentation or web UI code to this repository — they have dedicated homes above.

## 🌍 Language Requirements

- **Code comments**: Always write in English
- **Error messages**: Always write in English
- **Documentation**: Always write in English
- **Commit messages**: Use imperative mood and keep concise (e.g., "Fix Zabbix LLD key", "Add company discovery script")

## 📁 Repository Contents

### `doc/` / `docs/`
Internal technical documentation and OpenAPI specs. User-facing documentation belongs in [multiflexi-doc-en](https://github.com/VitexSoftware/multiflexi-doc-en).

### `debian/`
Debian packaging metadata for the `multiflexi-common` package.

## 📦 Debian Packaging Rules

### Makefile / debian/rules
- **Never use heredocs** (`<<EOF`) in `debian/rules` — `make` executes each recipe line in a separate shell, so multi-line heredocs break silently
- **Static files** belong in `debian/` as plain files, installed via `dh_install` or `install -D` — never generate them dynamically in the build
- **Line continuations**: Use backslash (`\`) to join multi-line shell commands in Makefile recipes
- **Tabs required**: All Makefile recipe lines must start with a tab character, not spaces

## 📋 Schema Validation

### Application Definition Files
- **Pattern**: `*.app.json`
- **Schema**: https://raw.githubusercontent.com/VitexSoftware/php-vitexsoftware-multiflexi-core/refs/heads/main/multiflexi.app.schema.json
- **Requirement**: All app.json files must conform to this schema

### Credential Type Files
- **Pattern**: `*.credential-type.json`
- **Schema**: https://raw.githubusercontent.com/VitexSoftware/php-vitexsoftware-multiflexi-core/refs/heads/main/multiflexi.credential-type.schema.json
- **Requirement**: All credential-type.json files must conform to this schema

## 📖 Documentation Standards

- User-facing documentation goes to [multiflexi-doc-en](https://github.com/VitexSoftware/multiflexi-doc-en)
- Internal technical docs in `docs/` follow reStructuredText (reST) format
- Comments explain the **why**, not the what

---
*This file ensures GitHub Copilot follows MultiFlexi Common project standards and conventions.*
