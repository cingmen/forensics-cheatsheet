# 🕵️ forensics-cheatsheet / Cheatsheet Forensik Digital

> Referensi praktis DFIR (Digital Forensics & Incident Response) berbahasa Indonesia — metodologi, perintah, dan template. Berdasarkan sumber pengetahuan publik.

<!-- ![Banner](assets/banner.png) — akan ditambahkan di rilis v0.2.0 -->

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-blue.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Last Commit](https://img.shields.io/github/last-commit/cingmen/forensics-cheatsheet)](https://github.com/cingmen/forensics-cheatsheet/commits)
[![Stars](https://img.shields.io/github/stars/cingmen/forensics-cheatsheet?style=social)](https://github.com/cingmen/forensics-cheatsheet/stargazers)
[![Contributors](https://img.shields.io/github/contributors/cingmen/forensics-cheatsheet)](https://github.com/cingmen/forensics-cheatsheet/graphs/contributors)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

## 📖 Apa ini? / What is this?

`forensics-cheatsheet` adalah koleksi cheatsheet digital forensik dan incident response untuk praktisi keamanan Indonesia. Semua konten ditulis berdasarkan sumber pengetahuan publik — standar internasional (NIST, ISO, RFC), dokumentasi resmi tool open-source, dan buku-buku forensik publik.

**⚠️ Penting**: Repo ini TIDAK berafiliasi dengan EC-Council, (ISC)², GIAC, atau badan sertifikasi apapun. Tidak ada materi berbayar, exam dumps, atau konten yang dilindungi NDA yang direproduksi. Lihat [DISCLAIMER.md](DISCLAIMER.md).

## ✨ Features / Fitur

- 🎯 **12 cheatsheet utama** — dari metodologi sampai report writing
- 🛠️ **Tool reference** — oneliner command untuk dd, Volatility 3, tshark, dll
- 📋 **Document templates** — Chain of Custody form, Forensic Report, Intake Form, IR Checklist
- 📚 **Public standards summary** — NIST SP 800-86, ISO 27037, RFC 3227
- 🇮🇩 **Bahasa Indonesia primer** — accessible untuk SOC analyst lokal
- 🔄 **Active maintenance** — update bulanan, kontribusi welcome

## 📦 What's Inside / Isi Repo

| Directory | Description |
|---|---|
| `cheatsheets/` | 12 file markdown fokus topik (methodology → report writing) |
| `tools/` | Reference per-tool (dd, Volatility, tshark, dll) |
| `templates/` | Form & report template siap pakai |
| `references/` | Summary standar publik |
| `docs/` | Dokumentasi tambahan (install, struktur, screenshots) |
| `assets/` | Banner, logo, color palette |

## 🚀 Quick Start / Mulai Cepat

### Baca online

Langsung browse folder [`cheatsheets/`](cheatsheets/) di GitHub.

### Clone untuk offline

```bash
git clone https://github.com/cingmen/forensics-cheatsheet.git
cd forensics-cheatsheet
```

### Pakai template

Copy file di `templates/` ke kasus kamu, isi placeholder `[...]`.

## 📚 Cheatsheet Index / Daftar Cheatsheet

| # | Topic | Link |
|---|---|---|
| 00 | Methodology | [Link](cheatsheets/00-methodology.md) |
| 01 | Chain of Custody | [Link](cheatsheets/01-chain-of-custody.md) |
| 02 | Evidence Acquisition | [Link](cheatsheets/02-evidence-acquisition.md) |
| 03 | Volatile Order | [Link](cheatsheets/03-volatile-order.md) |
| 04 | Disk Forensics | [Link](cheatsheets/04-disk-forensics.md) |
| 05 | Memory Forensics | [Link](cheatsheets/05-memory-forensics.md) |
| 06 | Network Forensics | [Link](cheatsheets/06-network-forensics.md) |
| 07 | Windows Artifacts | [Link](cheatsheets/07-windows-artifacts.md) |
| 08 | Linux Artifacts | [Link](cheatsheets/08-linux-artifacts.md) |
| 09 | Mobile Forensics | [Link](cheatsheets/09-mobile-forensics.md) |
| 10 | Anti-Forensics | [Link](cheatsheets/10-anti-forensics.md) |
| 11 | Report Writing | [Link](cheatsheets/11-report-writing.md) |

## 🤝 Contributing / Kontribusi

Kontribusi sangat welcome! Lihat [CONTRIBUTING.md](CONTRIBUTING.md).

**Quick wins:**
- Fix typo / clarify explanation
- Tambah command example di tools/
- Tambah referensi publik di section References
- Translate cheatsheet ke English (di branch `i18n-en`)

## ⚠️ Disclaimer / Disclaimer

Lihat [DISCLAIMER.md](DISCLAIMER.md) untuk detail lengkap. Singkatnya:

- Repo ini TIDAK berafiliasi dengan vendor sertifikasi apapun
- Semua konten berdasarkan sumber publik
- Tidak ada exam dumps atau NDA-protected content
- Kalau ada copyright concern, buka issue untuk takedown

## 📝 License / Lisensi

[CC-BY-4.0](LICENSE) — bebas pakai, modifikasi, distribusi dengan atribusi.

Topik GitHub (topics): `dfir, digital-forensics, incident-response, cheatsheet, cybersecurity, security, forensics, memory-forensics, network-forensics, windows-forensics, linux-forensics, volatility, autopsy, wireshark, nist, iso-27037, open-source, study-notes, reference, indonesia`

## 🔗 Related Repos / Repo Terkait

- [cingmen/osint-harian](https://github.com/cingmen/osint-harian) — Daily OSINT tracker

---

**Maintained by**: [@cingmen](https://github.com/cingmen) · **Last updated**: 2026-10-21
