# Autopsy Workflow / Alur Kerja Autopsy

> **TL;DR**: Langkah praktis setup Autopsy case — dari ingest image, menjalankan ingest module, sampai menyimpan artifacts dan melaporkan temuan.

## Overview

Autopsy adalah frontend open-source untuk The Sleuth Kit: tool disk forensik paling umum dipakai untuk analisis Windows. Workflow ini mengasumsikan image sudah dibuat dan hash sudah diverifikasi (lihat cheatsheet [02 Evidence Acquisition](../../cheatsheets/02-evidence-acquisition.md)).

## Workflow / Alur Kerja

1. **New Case** — File → New Case; beri nama + nomor kasus, isi case type dan investigator.
2. **Import Image** — Add Data Source → pilih evidence `.dd/.img/.E01`; pastikan opsi **read-only** dan hash verification aktif di wizard.
3. **Configure Ingest Modules** — pilih module yang dijalankan otomatis (Recent Activity, File Type Identification, Embedded File Extractor, Keyword Search, Timeline, dsb). Modules bekerja berparalel; jangan semua, curahkan ke relevan kasus.
4. **File Triage** — Tree jendela kiri: **Data Artifacts** (web history, carve, keywords), **File Views** (deleted, slack, filesystem). Ekspor/expand item yang menarik.
5. **Tagging & Reporting** — tandai artefak penting dengan tag; gunakan built-in report generator (XML/HTML) untuk draft laporan.
6. **Hash Sets** — import hash set vendor (mis. NSRL) untuk list file known-good/known-bad — mempercepat pembuangan file OS bawaan.

## Common Pitfalls / Kesalahan Umum

- ⚠️ Jangan pernah jalan-kan analisis pada image asli, bukan working copy — Autopsy sendiri read-only, tetapi workflow lab harus menganalisis working-copy.py.
- ⚠️ Mengharapkan ingest modules mencakup semua — tambahkan keyword search manual dari artefak spesifik kasus.
- ⚠️ Tidak mencatat versi Autopsy di laporan — mulai dari 4.x, hasil module bisa berbeda antar Versi.

## References / Referensi

1. Autopsy Documentation — https://sleuthkit.org/autopsy/docs/
2. The Sleuth Kit Wiki — https://wiki.sleuthkit.org/
3. NIST CFTT — Computer Forensic Tool Testing — https://www.nist.gov/itl/ssd/software-quality-group/computer-forensics-tool-testing-program-cftt

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
