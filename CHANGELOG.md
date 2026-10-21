# Changelog

Semua perubahan menonjol di repo ini terdokumentasi di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning memakai [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- GitHub Pages docs site
- Terjemahan Inggris (branch `i18n-en`)
- Target tambahan KAPE dan contoh triage skala besar
- Screenshot dan banner final

## [0.1.2] — 2026-10-21

### Changed

- Lengkapi cheatsheet 03, 04, 05, 08, dan 10 sehingga seluruh 12 cheatsheet memenuhi ambang ~1500 kata.
- Tambah catatan virtualisasi/cloud, file carving, container artifacts, dan batasan analisis anti-forensik.

## [0.1.1] — 2026-10-21

### Fixed

- Restore the `Cross-references` section on `cheatsheets/11-report-writing.md` that was lost during an earlier rewrite.

## [0.1.0] — 2026-10-21

### Added

- Repository skeleton: LICENSE (CC-BY-4.0), README, DISCLAIMER, CONTRIBUTING, CODE_OF_CONDUCT (Contributor Covenant 2.1), SECURITY, CHANGELOG
- 12 cheatsheet inti (`cheatsheets/00`–`11`), masing-masing dengan referensi publik, common pitfalls, dan cross-references
- 5 template dokumen: chain of custody, forensic report, evidence intake, IR checklist, evidence label
- Tool references: dd/dcfldd, Volatility 3, tshark/Wireshark, Autopsy, Sleuth Kit, RegRipper, RECmd, KAPE, ADB
- Ringkasan standar publik: NIST SP 800-86, ISO/IEC 27037, RFC 3227, tabel volatile order
- Dokumentasi: `docs/INSTALL.md`, `docs/STRUCTURE.md`, `docs/badge-snippets.md`
- CI: markdown-lint dan link-check workflows, issue templates, PR template
- Aset: `assets/color-palette.json`

[Unreleased]: https://github.com/cingmen/forensics-cheatsheet/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/cingmen/forensics-cheatsheet/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/cingmen/forensics-cheatsheet/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cingmen/forensics-cheatsheet/releases/tag/v0.1.0
