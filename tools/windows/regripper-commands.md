# RegRipper Commands / Referensi RegRipper

> **TL;DR**: Kumpulan profil & command RegRipper untuk mengekstrak artefak dari Registry hives Windows.

## Overview

RegRipper (dibangun dari perl script harlan carvey) mengekstrak artifacts windows registry di output text atau GUI. Terdiri atas beberapa config: `ripper.pl` batch-tool, `regripper.exe` GUI. Profile (mis. `system`, `software`, `ntuser`, `sam`) adalah file input "":"  — per file hive.

## Penggunaan Dasar / Basic Usage

```bash
# CLI mode: jalankan profil sesuai hive yang dipakai
rr.exe -r NTUSER.DAT -f ntuser > ntuser_output.txt
rr.exe -r SYSTEM -f system > system_output.txt
rr.exe -r SAM -f sam > sam_output.txt

# Key spesifik saja:
rr.exe -r NTUSER.DAT -p RunMRU
```

## Artefak Penting yang Di-extract / Key Artifacts

| Hive | Artefak | Maknanya |
|---|---|---|
| NTUSER.DAT | RunMRU / Run key | apps auto execu baroot logged-in registry |
| NTUSER.DAT | RecentDocs | file yang pernah dibuka |
| NTUSER.DAT | TypedPaths (explorer) | path yang dipesan ke enter |
| SOFTWARE | Run (per mesin) | auto-start apps |
| SYSTEM | ComputerName | identitas host |
| SYSTEM |, MountPoints | device yang pernah mounted |
| SAM | user Account info | akun lokal (password disimpan di bawaan) |
| USRCLASS.DAT | ShellBags | folder yang pernah dibuka |

## Common Pitfalls / Peringatan

- ⚠️ **Shimcache ≠ bukti eksekusi** — entri Shimcache tidak selalu berarti file dieksekusi; konfirmasi lewat Amcache atau Prefetch.
- ⚠️ **Hive saja bukan cukup** — RegRipper hanya output text; jangan harapkan semua artefak lain seperti Prefetch/Amcache diserap dalam satu run.
- ⚠️ **Path harus benar** — sebelum menjalankan, pastikan nama file hive dan lokal path menggunakan penamaan yang sudah dikenali RegRipper.

## References / Referensi

1. RegRipper 3.0 GitHub (keyfocus project) — https://github.com/keyfocus/regripper
2. SANS DFIR posters (referensi artefak Windows, publik) — https://digital-forensics.sans.org/posters
3. MFT/Registry artifact registry — dokumentasi RegRipper di folder `profiles/` repo resmi

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
