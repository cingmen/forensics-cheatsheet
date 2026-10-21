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

## SRUM dan Pemakaian Sumber Daya / SRUM Deep-Dive

System Resource Usage Monitor (SRUM) menyimpan data pemakaian sumber daya per aplikasi: berapa banyak data yang dikirim dan diterima, berapa lama aplikasi berjalan, dan kapan aktivitas itu terjadi. Data ini disimpan dalam database ESE (`SRUDB.dat`) di `C:\Windows\System32\sru`. Banyak investigator melewatkannya, padahal SRUM sangat berguna untuk kasus eksfiltrasi data.

Contohnya: sebuah host diduga mengirim data ke cloud storage pribadi. Prefetch menunjukkan aplikasi apa yang berjalan, tetapi tidak menunjukkan volume data. SRUM menutup celah itu: tabel network usage mencatat byte yang dikirim per aplikasi per jam. Jika terlihat aplikasi tak dikenal mengirim puluhan gigabyte pada jam di luar kerja, itu petunjuk kuat.

Untuk membaca SRUM, gunakan tool seperti `SrumECmd` atau library ESE (`libesedb`). Output biasanya berupa CSV yang bisa difilter per aplikasi dan rentang waktu. Catat versi tool dan waktu parsing di laporan, karena struktur SRUM berbeda antar versi Windows.

SRUM juga mencatat pemakaian CPU dan memori per aplikasi, yang berguna untuk kasus cryptomining: aplikasi tak dikenal memakai CPU tinggi selama berhari-hari. Kombinasikan dengan event log dan artefak eksekusi untuk memastikan aplikasi tersebut benar-benar berjalan, bukan hanya terpasang.

## Studi Kasus: Gerak Lateral / Lateral Movement Case

Sebuah akun layanan (`svc-backup`) tiba-tiba dipakai untuk login ke banyak server pada malam hari. Tim perlu membuktikan apakah ini aktivitas wajar atau penyalahgunaan. Berikut alur analisis dengan artefak Windows.

Pertama, periksa event log Security untuk Event ID 4624 (logon sukses) pada semua server. Filter berdasarkan akun dan tipe logon. Logon type 3 menunjukkan akses jaringan, sedangkan tipe 10 menunjukkan RDP. Waktu logon yang berdekatan di banyak host dalam hitungan menit adalah pola yang mencurigakan.

Kedua, periksa event log terkait layanan dan tugas terjadwal. Penyerang sering membuat scheduled task atau service baru untuk mempertahankan akses. Event ID 4698 (scheduled task dibuat) dan 7045 (service dipasang) adalah dua yang paling sering muncul.

Ketiga, periksa artefak eksekusi: Prefetch, Amcache, dan Shimcache di host yang menerima koneksi. Jika ada tool administratif seperti PsExec atau WMIC yang dijalankan dari akun tersebut, itu memperkuat dugaan lateral movement. Keempat, periksa registry untuk `Run` key dan service yang tidak wajar.

Kelima, cocokkan dengan log jaringan: koneksi SMB dari satu host ke banyak host lain dalam waktu singkat. Kombinasi event log, artefak eksekusi, dan flow jaringan membentuk gambaran yang utuh: akun layanan dipakai untuk menyebar ke beberapa server, dengan alat administratif yang sah tetapi disalahgunakan.

## Checklist Artefak Windows / Windows Artifact Checklist

- [ ] Versi Windows setiap host dicatat.
- [ ] Registry hives diekstrak (SAM, SYSTEM, SOFTWARE, NTUSER, USRCLASS).
- [ ] Event log yang relevan diekspor (Security, System, Sysmon, TerminalServices).
- [ ] Artefak eksekusi diperiksa: Prefetch, Amcache, Shimcache, BAM, SRUM.
- [ ] Persistence diperiksa: Run keys, services, scheduled tasks, WMI.
- [ ] Artefak USB dan MountPoints diperiksa bila relevan.
- [ ] Timestamp dikonversi dengan benar dan dicatat dalam UTC.
- [ ] Temuan dirujuk ke EV-ID dan dijelaskan di bagian findings.

## Pertanyaan Umum / FAQ

**Apakah Prefetch selalu tersedia?** Tidak. Prefetch bisa dimatikan pada SSD atau server, dan bisa dibersihkan oleh tool pembersih. Jika tidak ada, gunakan Amcache atau Shimcache sebagai pengganti, dengan catatan keterbatasannya.

**Mengapa event log hanya menyimpan beberapa hari?** Ukuran maksimum log default terbatas, sehingga log lama terrotasi. Periksa juga arsip log dan SIEM bila tersedia. Ketiadaan log bukan bukti tidak ada aktivitas.

**Apakah artefak Windows bisa dimanipulasi?** Bisa. Timestomping dan penghapusan log adalah teknik umum. Karena itu cross-check antar artefak dan dengan sumber jaringan sangat penting.

## Membaca Hive Tanpa Windows / Reading Hives Offline

Hive Registry adalah file biner. Untuk membacanya di Linux atau tanpa membuka Windows, ada beberapa pendekatan yang lazim.

Pertama, gunakan library `libregf` (bagian dari libyal) atau `python-registry`. Keduanya bisa membaca hive langsung dan mengekspor key/value ke format teks. Kedua, gunakan Registry Explorer (GUI) atau RegRipper (CLI) di mesin analisis Windows yang terisolasi. Ketiga, decode manual dengan `regf` parser bila hanya butuh key tertentu.

Jika hive berasal dari image disk, ekstrak dulu dengan TSK: `icat -o <offset> <inode> > SYSTEM`. Setelah diekstrak, hash file hive dan catat di form chain of custody sebelum dianalisis. Jangan pernah membuka master image secara langsung dengan tool yang bisa menulis.

Perhatikan juga hives yang tidak aktif. Windows menyimpan salinan hive di `System Volume Information` (restore point), `Windows.old`, dan folder profile lama. Hive lama ini bisa memuat konfigurasi sebelum insiden, sehingga berguna untuk perbandingan.

## References / Referensi

1. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. MITRE ATT&CK — https://attack.mitre.org/
3. SANS DFIR posters (Windows artifacts, publik) — https://digital-forensics.sans.org/posters
4. libforensics Windows forensic artifacts (public availability) — https://github.com/kostaz/libforensics

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
