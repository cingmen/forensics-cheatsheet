# RECmd Commands / Referensi RECmd

> **TL;DR**: RECmd (dari package Eric Zimmerman tools) mengekstrak data Registry dengan batch file JSON — alternatif yang cepat dan terstruktur dibanding RegRipper.

## Overview

RECmd adalah tool CLI untuk parsing Registry hives. Dengan batch file (JSON), satu run bisa menghasilkan output CSV yang terstruktur, mudah diproses di Excel/Pandas. Tool tersedia gratis di Eric Zimmerman's suite — dokumentasi resmi mencantumkan parameter lengkap.

## Penggunaan Dasar / Basic Usage

```bash
# Gunakan batch file built-in dengan output CSV
RECmd.exe --bn BatchExamples\Kroll_Limited.json --csv . --csvf output --hive NTUSER.DAT

# Jalankan key tertentu pada hive
RECmd.exe --hive NTUSER.DAT --key "Software\\Microsoft\\Windows\\CurrentVersion\\Run"

# Batch file custom: per spesifikasi JSON di repo resmi
```

## Batch Files / Batch Files yang Umum

| Batch JSON | Tujuan |
|---|---|
| `Kroll_Limited.json` | key aggregates yang biasa dipakai kasus |
| `BatchExamples.json` | contoh persisna custom |
| Custom JSON | berisi key-path yang hendak dilacak per kasus |

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Salah nama hive** — periksa path hive dulu (`NTUSER.DAT`, `SYSTEM`, `SAM`, `SOFTWARE`, `USRCLASS.DAT`).
- ⚠️ **Lupa --csv flag** — bila dikosongkan output berupa STDOUT raw. - ⚠️ **Batch file invalid JSON** — cek sintaks batch file sebelum menjalankan; periksa juga kompa local path.

## References / Referensi

1. RECmd / Registry Explorer documentation — https://ericzimmerman.github.io/#!index.md
2. Eric Zimmerman tool suite GitHub — https://github.com/EricZimmerman/RECmd
3. SANS DFIR posters — https://digital-forensics.sans.org/posters

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
