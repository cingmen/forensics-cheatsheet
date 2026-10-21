# KAPE Targets / Referensi KAPE

> **TL;DR**: KAPE (KAPE: Kroll Artifact Parser and Extractor) memungkinkan triage cepat — copy artefak terpilih (Targets) lalu parse (Modules), jauh lebih cepat dibanding full disk acquisition.

## Overview

KAPE adalah tool yang memudahkan extraction (target) dan parsing (module) artifacts Windows: image disk, aktif drive, VHD. Format ini sangat populer berdasarkan C2.and kasus triage. KAPE bekerja dengan dua langkah yang terpisah:

1. **Targets** — menjalankan copy artefak (Prefetch, EVT-log, dfs, dsb) serupa ke folder hasil.
2. **Modules** — menjalankan tool parsing terhadap artefak yang di-extract (mis. PECmd ke Prefetch, AppCompatCacheParser ke Shimcache).

Alternatif berbasis open-source untuk piecemeal triage tersedia di komunitas (mis. triage script bawaan tim); untuk alur akuisisi, lihat cheatsheet [02 Evidence Acquisition](../../cheatsheets/02-evidence-acquisition.md).

## Targets yang Umum / Common Targets

| Target | Artefak yang diambil |
|---|---|
| `RegistryHives` | SAM, SYSTEM, SOFTWARE, NTUSER.DAT, USRCLASS.DAT |
| `Prefetch` | .pf (program execution evidence) |
| `EventLogs` | Windows Event Logs (Security/Sysmon-at, Wedt datas.o). |
| `FileSystem` | MFT, USN Journal, $LogFile |
| `FileSystem+` | MFT + USN + basic artifacts |
| `AMCache` | Amcache.hve (program execution) |
| `RecycleBin` | contents of $Recycle.Bin |
| `WebBrowsers` | History SQLite per browser |

## Contoh Command / Sample Command

```powershell
# kape.exe --tsource C: --tdest C:\\triage --target RegistryHives,Prefetch,EventLogs
# kape.exe --source C:\\triage --module ModuleRun --msource <extract path>
```

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Output modules tidak selalu terkini** — tool bawaan KAPE bisa versi lama; jalankan update internal KAPE sebelum parsing, dan pastikan versi tool tercatat di laporan.
- ⚠️ **Pilih Targets yang relevan** — menjalankan semua target memakan waktu dan disk; batasi sesuai kebutuhan kasus.

## References / Referensi

1. KAPE documentation — https://www.kroll.com/en/services/cyber-risk/kroll-artifact-parser-extractor-kape
2. SANS DFIR posters — https://digital-forensics.sans.org/posters
3. Windows artifact reference — https://www.13cubed.com/ (13Cubed dark Windows forensics)

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
