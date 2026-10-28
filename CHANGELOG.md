# Changelog

Semua perubahan menonjol di repo ini terdokumentasi di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning memakai [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [Unreleased]

### Added
- cheatsheets: `06-network-forensics.md` — bagian baru hasil penyarian materi modul pelatihan *Network Forensics* (Exam 312-49, Modul 08, rev. 2024-06-20) yang dikontribusikan:
  - **Postmortem vs Real-Time analysis** (tabel perbandingan mode pemeriksaan log).
  - **Empat jenis bukti jaringan**: full content, session, alert, statistical data.
  - **Peta bukti per lapisan TCP/IP** (Application → Network Access) beserta sumber lognya.
  - **Taksonomi serangan kabel (13) & nirkabel (8)** dalam bentuk tabel dengan petunjuk deteksi.
  - **IoC level jaringan**: traffic outbound tak lazim, URL berbahaya, user-agent aneh, anomali login, request berulang, port tak wajar.
  - **Kesiapan forensik jaringan**: kriteria legal keterterimaan log (Rule 803 FRE, FISMA/HIPAA/PCI DSS/SOX/GLBA), enam pedoman kredibilitas log (log everything, NTP, multiple sensors, missing logs, system integrity, access control), autentisitas & integritas log (hash, enkripsi, custodian).
  - **Manajemen log terpusat**: syslog, tiga tier infrastruktur log, praktik terbaik, tantangan + solusi (NIST SP 800-92).
  - **Korelasi event**: empat langkah (aggregation, masking, filtering, root cause analysis), tipe same/cross-platform, tiga prasyarat (transmisi, normalisasi, reduksi data), dan 13 pendekatan korelasi.
  - Blok perintah baru: `ntpq`/`chronyc`, `w32tm` + registry W32Time, `sha256sum`/`md5sum`/`certutil`/`fsum`, `gpg`, `logger`/rsyslog forwarding, canary berkala untuk deteksi log hilang.
  - Contoh korelasi event brute-force (menyusul contoh beaconing yang sudah ada).
- docs: `glossary.md` baru — 35 istilah forensik jaringan/logging dengan definisi singkat (Bahasa Indonesia) + sumber publik.

### Changed
- cheatsheets: `06-network-forensics.md` — struktur & konten diperluas:
  - TL;DR diperbarui mencakup log, kesiapan forensik, dan korelasi event (sebelumnya hanya PCAP/tshark).
  - Overview ditambah framing tujuan ganda forensik jaringan dan tantangan capture/analisis.
  - Workflow diperluas 6 → 8 langkah (tambah: amankan bukti/hash, korelasi event lintas sumber).
  - Common Pitfalls ditambah 4 item logging (log di host terkompromi, hash akuisisi, retensi, jam tidak sinkron).
  - Checklist diperluas 7 → 12 item (tambah: hash & CoC, NTP drift, kontrol akses log, IoC lintas log, korelasi event).
  - FAQ ditambah 2 pertanyaan (autentisitas log vs tampering, kebijakan retensi log).
  - Referensi ditambah RFC 5424 (Syslog), RFC 5905 (NTP), NIST SP 800-92, NIST SP 800-86, FRE Rule 803.
  - Cross-references ditambah: 00 Methodology, 01 Chain of Custody, 11 Report Writing, docs/glossary.md, templates/.
- Heading bagian baru memakai Bahasa Indonesia penuh sesuai preferensi repo; bagian lama dipertahankan.

### Catatan lisensi
- Materi disarikan ulang dengan kata-kata sendiri (tidak menyalin prosa sumber); konsep bersandar pada sumber publik: NIST SP 800-86/800-92, RFC 3227/5424/5905, Federal Rules of Evidence Rule 803. Tetap kompatibel dengan CC-BY-4.0.

### Suggested commit message

```text
feat(cheatsheets): perluas 06-network-forensics dengan logging, forensic readiness, dan korelasi event
```

- tambah materi: jenis bukti jaringan, peta bukti per lapisan TCP/IP,
  taksonomi serangan kabel/nirkabel, IoC jaringan, kriteria legal log
  (Rule 803 FRE), 6 pedoman kredibilitas log, syslog & centralized log
  management, korelasi event (4 langkah + 13 pendekatan)
- tambah blok perintah: NTP/W32Time, hash & enkripsi log, syslog
  forwarding, canary deteksi log hilang
- tambah docs/glossary.md (35 istilah), perbarui workflow/pitfalls/
  checklist/FAQ/referensi
- sumber: modul pelatihan Network Forensics (312-49 M08, 2024-06-20),
  disarikan dari sumber publik NIST SP 800-86/92, RFC 3227/5424/5905

```text


### Suggested version bump
`0.1.2` → **`0.2.0`** — penambahan konten signifikan (minor bump, SemVer).

---

## [0.2.0] — 2026-10-29
*(alternatif: rilis langsung — pindahkan semua entri di atas ke sini dan hapus blok [Unreleased])*

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
