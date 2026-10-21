# Volatility 3 Cheatsheet / Referensi Plugin Volatility 3

> **TL;DR**: Daftar plugin Volatility 3 yang paling sering dipakai di investigasi — proses, network, malware, registry — dengan tujuan tiap plugin dan petunjuk interpretasi hasil.

## Overview / Gambaran Umum

Volatility 3 adalah framework forensik memori open-source de facto. Berbeda dari v2 yang butuh `--profile`, v3 otomatis mendeteksi versi Windows dari isi kernel image. Perintah dasarnya `vol -f memdump.dmp <plugin>`. Instal: `pip install volatility3`. Cheatsheet ini fokus plugin Windows; dukungan Linux/Mac juga tersedia di dokumentasi resmi.

## Daftar Plugin Sering Dipakai / Common Plugins

| Plugin | Tujuan | Kapan dipakai |
|---|---|---|
| `windows.info` | metadata image (versi OS, arch, KDBG) | selalu, pertama kali |
| `windows.pslist` | daftar proses aktif | baseline proses |
| `windows.pstree` | pohon proses parent/child | deteksi anomali proses |
| `windows.psscan` | scan pool untuk proses hidden/unlinked | detek malware |
| `windows.cmdline` | argumen command line tiap proses | cek aktivitas wajar |
| `windows.netscan` | endpoint TCP aktif di memori | cek C2 |
| `windows.malfind` | cari memori executable + injected code | hunt malware |
| `windows.dlllist` | DLL per proses | cek injection |
| `windows.handles` | handle file/registry per proses | deep-dive proses |
| `windows.registry.hivelist` | daftar hive yang aktif | forensik registry |
| `windows.registry.printkey` | cetak value di key tertentu | persistence check |
| `windows.dumpfiles` | ekstrak file dari memori | sampel file |
| `windows.memmap` | memory map per proses | dump memori |
| `windows.clipboard` | isi clipboard | bukti aktivitas |
| `windows.shimcache` | artefak eksekusi program | execution history |
| `windows.timeliner` | timeline dari artefak memori | penyusunan timeline |

## Common Patterns / Pola Investigasi

```bash
# 1. Identifikasi OS & baseline
vol -f dump.dmp windows.info
vol -f dump.dmp windows.pslist | head -20

# 2. Cari proses mencurigakan: parent yang aneh, path yang tidak standar
vol -f dump.dmp windows.pstree
vol -f dump.dmp windows.cmdline --pid "$PID"

# 3. Bandingkan pslist vs psscan — proses hidup vs proses yang dihapus
vol -f dump.dmp windows.psscan

# 4. Hunt injected code & C2 traffic
vol -f dump.dmp windows.malfind
vol -f dump.dmp windows.netscan

# 5. Persistence via registry
vol -f dump.dmp windows.registry.printkey --key Software\\Microsoft\\Windows\\CurrentVersion\\Run
```

## Common Pitfalls / Kesalahan Umum

- ⚠️ Memori yang terlambat dicapture — host yang sudah di-reboot mungkin tidak berguna; capture memory sebelum isolate.
- ⚠️ Mengabaikan hasil `psscan` — proses bisa disembunyikan lewat DKOM; `pslist` saja tidak cukup.
- ⚠️ Membaca `malfind` sebagai fakta — hasil malfind adalah indikator; verifikasi dengan analisis dump file dan konteks proses yang bersangkutan.

## References / Referensi

1. Volatility 3 Documentation — https://volatility3.readthedocs.io/
2. Volatility GitHub Repository — https://github.com/volatilityfoundation/volatility3
3. NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
