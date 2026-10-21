# Windows Artifacts Cheatsheet / Cheatsheet Artefak Windows

> **TL;DR**: Peta artefak Windows yang paling sering dirujuk — Registry hives, Event Logs (EVTX), Prefetch, Amcache, Shimcache, BAM/DAM, SRUM, RDP cache — dengan alat parsing (RegRipper, RECmd, KAPE) dan cara interpretasi yang benar.

## Overview / Gambaran Umum

Artefak Windows adalah jejak yang ditulis sistem secara alami saat beroperasi: program dieksekusi, pengguna login, USB dipasang, sesi RDP dibuka. Karena sistemlah yang menuliskannya (bukan penyerang), artefak ini sangat berguna untuk membangun timeline tanpa perlu host yang dipantau per detik.

Bergantung versi Windows (7/10/11/Server), lokasi dan format artefak bisa berbeda. Karena itu penting memastikan versi Windows setiap host sebelum menafsirkan artefaknya.

Tool yang umum dipakai: RegRipper dan RECmd untuk Registry, python-evtx untuk Event Log, dan KAPE untuk triage many-artefak sekaligus. Tabel target KAPE relevan ada di `tools/windows/kape-targets.md`.

## Key Concepts / Konsep Kunci

### Registry Hives / Hive Reg

Hive penting dan maknanya:

| Hive | Path Asal | Artefak yang bisa dibaca |
|---|---|---|
| NTUSER.DAT | `<user profile>` | Run, RecentDocs, TypedPaths, RunMRU |
| SAM | `C:\Windows\System32\config` | akun lokal, RID, login info |
| SYSTEM | `C:\Windows\System32\config` | ComputerName, MountPoints, services |
| SOFTWARE | `C:\Windows\System32\config` | Run (machine-wide), Uninstall list |
| UsrClass.dat | `<user profile>\AppData\Local` | ShellBags, MuIRCy cache |

Persistence yang paling sering dilihat: `...\CurrentVersion\Run` dan `RunOnce` di hive per-user dan machine — berarti program/auto-start yang aktif.

### Program Execution / Artefak Program Run

| Artefak | Sumber file | Makna |
|---|---|---|
| **Prefetch** | `C:\Windows\Prefetch\*.pf` | program dieksekusi lebih dari cukup kali; pass cmdline |
| **Amcache** | `C:\Windows\appcompat\Amcache.hve` | referensi program + SHA1 file |
| **Shimcache** | `%SISTEM%\SYSTEM hive` | urutan program yang dieksekusi |
| **BAM/DAM** | `SYSTEM hive` — CurrentControlSet\Services\bam | program yang berjalan terakhir diper-user |
| **SRUM** | `C:\Windows\System32\sru` | network/pekerjaan usage per aplikasi |

Interpretasi: Prefetch/Amcache/Shimcache adalah bukti eksekusi; gabungan kedua timestamps-nya memperbaiki ketelitian timeline program run.

### Event Logs (EVTX) / Log Kejadian

- Log **Security** memuat login events (4624 sukses, 4625 gagal) lengkap dengan akun, workstation, dan logon type.
- **Sysmon** (opsional, di-install manual) memperkaya log dengan process creation, network connection, dan driver load — sangat berguna bila sudah terpasang sebelum insiden.
- **TerminalServices-LocalSessionOperations / RemoteConnectionManager** mencatat koneksi RDP: host, akun, waktu.

## Commands / Perintah

```bash
# === RegRipper: ekstraksi per hive ===
rr.exe -r NTUSER.DAT -f ntuser > ntuser.txt
rr.exe -r SYSTEM -f system > system.txt
rr.exe -r SOFTWARE -f software > software.txt

# === RECmd: batch parse ===
RECmd.exe --bn BatchExamples\\Kroll_Limited.json --csv . --csvf results --hive NTUSER.DAT

# === KAPE: triage banyak artefak sekali jalan ===
# kape.exe --tsource C: --tdest <out> --target RegistryHives,Prefetch,EventLogs

# === Evtx parser (python) ===
# pip install python-evtx
evtx_dump Security.evtx > Security.xml
```

## Tabel Artefak Program Run / Program Run Table

| Sumber | Lokasi | Catatan interpretasi |
|---|---|---|
| Prefetch `.pf` | `C:\Windows\Prefetch` | execution count + timestamps terakhir |
| Amcache.hve | `C:\Windows\appcompat` | SHA1 file yang dieksekusi |
| Shimcache | SYSTEM hive | order-of-run; perlu konfirmasi eksekusi |
| BAM/DAM | SYSTEM hive | program terakhir run per user |
| SRUM | `C:\Windows\System32\sru` | network usage & app usage per aplikasi |

## Workflow / Alur Kerja

1. **Verifikasi & salin** — bekerja di working copy; catat hashnya di CoC.
2. **Registry triage** — ekstrak hives via RegRipper/RECmd; terutama Run keys, ShellBags, RecentDocs.
3. **Event Log triage** — cari login 4624/4625, account management, service install, sysmon (mis. process creation event 1).
4. **Program execution** — Prefetch, Amcache, Shimcache, BAM, SRUM; kumpulkan di tabel persis.
5. **Network & RDP** — TerminalServices logs, RDP Cache (bcache), Firewall log.
6. **Timeline** — susun artefak di satu timeline; temuan disk vs log vs network dihubungkan.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Shimcache ≠ eksekusi** — nama file di Shimcache tidak selalu berarti file dieksekusi; konfirmasi lewat Amcache/Prefetch.
- ⚠️ **Hanya melihat Run key** — persistence modern bisa lewat scheduled task, service, WMI subscription, atau startup folder; kaji juga lokasi lain.
- ⚠️ **Tidak memeriksa hive lama** — hive per-user dari profile lama bisa masih ada (Windows.old, profile lain); jangan dilewati.
- ⚠️ **Kesalahan konversi timestamp** — artefak Windows menyimpan FILETIME (100 ns sejak 1601-01-01 UTC); pastikan tool mengonversi benar ke zona investigasi.
- ⚠️ **Log rotation** — event security bisa dirotasi saat disk penuh; cek apakah ada backup log lain sebelum menyimpulkan "tidak ada kejadian".

## Cross-references / Referensi Silang

- [04 Disk Forensics](../cheatsheets/04-disk-forensics.md) — berlaku Windows disk image parsing.
- [05 Memory Forensics](../cheatsheets/05-memory-forensics.md) — registry via RAM yang sync.
- [06 Network Forensics](../cheatsheets/06-network-forensics.md) — korek jaringan ke host.

## References / Referensi

1. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. MITRE ATT&CK — https://attack.mitre.org/
3. SANS DFIR posters (Windows artifacts, publik) — https://digital-forensics.sans.org/posters
4. libforensics Windows forensic artifacts (public availability) — https://github.com/kostaz/libforensics

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
