# Volatile Order Table / Tabel Urutan Volatilitas

> **TL;DR**: Tabel ringkas urutan pengumpulan data berdasarkan RFC 3227 — dari data yang paling cepat hilang (register, cache) sampai yang paling stabil (backup) — lengkap dengan contoh command capture di Windows dan Linux.

## Tabel Utama / Main Table

| Order | Data | Cepat hilang saat? | Command Windows (contoh) | Command Linux (contoh) |
|---|---|---|---|---|
| 1 | Registers, CPU cache | saat power-off | (via memory dump) | (via memory dump) |
| 2 | RAM (memory) | saat power-off | `winpmem memdump.raw` / FTK Imager | `avml memdump.raw` / `LiME` |
| 3 | Routing table, ARP cache, process table, kernel stats, connections | saat reboot | `route print`, `arp -a`, `tasklist`, `netstat -ano` | `ip r`, `ip n`, `ps auxf`, `ss -tulnp` |
| 4 | Temporary file systems | saat reboot/cleanup | `%TEMP%`, pagefile | `tmpfs/` mount, `/tmp` |
| 5 | Disk (filesystem) | saat overwrite / pembersihan | full disk image (dcfldd) | full disk image (ddrescue) |
| 6 | Remote logging & monitoring data | saat berpindah / dihapus SIEM | export SIEM log | export syslog/SIEM |
| 7 | Physical config, network topology | saat diubah secara fisik | dokumentasi lokasi | dokumentasi lokasi |
| 8 | Archival media (backup) | paling stabil | restore from backup | restore from backup |

## Prinsip Praktis / Practical Principles

1. **Capture dari atas ke bawah** — mulai dari yang paling volatile; memori dulu, disk kemudian.
2. **Jangan shutdown** — isolasi jaringan lebih aman daripada mematikan daya; shutdown menghapus layer 1–4.
3. **Waktu itu penting** — setiap capture mengubah host; catat hal yang berubah di log investigasi.
4. **Hash semua hasil capture** — tiap layer yang diambil disertai hash dan terdaftar di chain of custody.

## Workflow Capture Cepat / Quick Capture Workflow

1. Foto layar dan kondisi fisik host.
2. Capture memory (Layer 2).
3. Tangkap state jaringan & proses (Layer 3 command di atas).
4. Copy temporary dan log aktif bila relevan.
5. Lanjut full disk acquisition dengan write blocker.
6. Catat semua di chain of custody.

## References / Referensi

1. RFC 3227 — Guidelines for Evidence Collection and Archiving — https://www.rfc-editor.org/rfc/rfc3227
2. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
3. ISO/IEC 27037:2012 — https://www.iso.org/standard/44381.html

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
