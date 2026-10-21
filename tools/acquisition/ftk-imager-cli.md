# FTK Imager CLI / Referensi FTK Imager Command Line

> **TL;DR**: FTK Imager (freeware, Exterro) menyediakan versi CLI untuk membuat image disk dan capture memori secara otomatis — berguna untuk triage skala besar dan scripting.

## Overview / Gambaran Umum

FTK Imager tersedia dalam dua bentuk: aplikasi GUI dan binary command line (`ftkimager.exe` di Windows). Versi CLI menghasilkan image dalam format E01, raw (dd), atau SMART, dan bisa menjalankan capture memori lewat `--capture-memory`. Karena freeware (bukan open-source), command di halaman ini diambil dari dokumentasi resmi dan `--help` bawaan; selalu cek versi yang terpasang karena flag bisa berubah.

Cheatsheet ini hanya memuat command yang umum dipakai. Untuk analisis, FTK Imager bisa membuka image dan melakukan mount read-only, tetapi untuk pekerjaan otomatis di Linux, tool open-source seperti `dcfldd`/`ddrescue` lebih mudah diintegrasikan.

## Command Dasar / Basic Commands

```bat
:: List disk fisik yang tersedia
ftkimager --list-drives

:: Buat E01 dari disk fisik (Windows)
ftkimager \\.\PhysicalDrive0 E:\evidence\case-014 --e01 --frag 4G ^
          --compress 6 --case-number CASE-2026-014 ^
          --evidence-number EV-2026-014 --description "Laptop karyawan"

:: Buat raw image (dd) dari disk yang sama
ftkimager \\.\PhysicalDrive0 E:\evidence\case-014 --raw

:: Capture memori (butuh hak administrator)
ftkimager --capture-memory E:\evidence\memdump.raw
```

## Opsi Penting / Key Options

| Opsi | Fungsi |
|---|---|
| `--e01` | Format E01 dengan metadata kasus |
| `--raw` | Format raw/dd |
| `--frag <size>` | Ukuran fragmen untuk E01 (mis. 4G) |
| `--compress <0-9>` | Tingkat kompresi E01 |
| `--case-number` | Nomor kasus yang disimpan di header E01 |
| `--evidence-number` | Nomor bukti yang disimpan di header E01 |
| `--description` | Deskripsi bukti |
| `--verify` | Verifikasi image setelah pembuatan |
| `--capture-memory` | Capture RAM ke file raw |

## Verifikasi / Verification

FTK Imager menulis hash MD5/SHA-1 di akhir proses dan menyimpannya di header E01. Untuk verifikasi independen di Linux:

```bash
# Baca hash dari image E01 (memerlukan libewf)
ewfinfo evidence.E01 | grep -i hash

# Bandingkan dengan hash yang tercatat di form CoC
sha256sum evidence.raw
```

Selalu cocokkan hash yang dilaporkan tool dengan hash independen. Jika berbeda, ulangi akuisisi dan catat kejadiannya di chain of custody.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Menjalankan tanpa hak administrator** — akses ke disk fisik akan ditolak; catat kegagalan dan ulangi dengan izin yang sesuai.
- ⚠️ **Salah memilih drive** — `--list-drives` wajib dijalankan sebelum akuisisi; nomor disk bisa berubah setelah perangkat USB dipasang.
- ⚠️ **Tidak memakai `--verify`** — verifikasi bawaan lebih murah daripada mengulang akuisisi berjam-jam.
- ⚠️ **Mengabaikan metadata kasus** — header E01 tanpa case/evidence number menyulitkan penelusuran; isi selalu.

## References / Referensi

1. FTK Imager User Guide (Exterro) — https://www.exterro.com/ftk-imager
2. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
3. libewf (EWF tools) — https://github.com/libyal/libewf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
