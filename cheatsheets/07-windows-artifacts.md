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

## Artefak Tambahan Windows / Additional Windows Artifacts

Selain artefak eksekusi di atas, artefak berikut sering memberi konteks: kapan aplikasi dipasang atau dihapus, gambar apa yang pernah dibuka, data pencarian yang tersimpan, dan jejak browsing.

### Prefetch Parameters / Pengaturan Prefetch

Sebelum menganalisis artefak Prefetch, pastikan fiturnya benar-benar aktif. Nilai konfigurasi ada di:

```text
HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters
```

Nilai `EnablePrefetcher` di key itu memiliki arti: `0` = mati, `1` = prefetch aplikasi saja, `2` = prefetch boot saja, `3` = aplikasi + boot. Server modern biasanya mematikan prefetch (SSD & manajemen RAM), jadi folder `Prefetch` yang tampak kosong perlu dibaca bersama nilai key ini sebelum disimpulkan "tidak ada eksekusi". Tiap `.pf` melacak file yang diload aplikasi dalam ±10 detik pertama sejak program dimulai — kaitkan timestamp `.pf` (UTC) dengan Registry/event log untuk menjawab "siapa yang menjalankan".

Parsenya: WinPrefetchView (NirSoft, GUI) untuk penelusuran visual, atau `PECmd` (EZ tools) untuk output CSV yang rapi.

### System Restore Points / Titik Pemulihan

Folder restore point menyimpan snapshot konfigurasi:

| Lokasi | Isi |
|---|---|
| `\System Volume Information\_restore{GUID}\RP##\` | folder per restore point, diberi nomor `RP##` |
| `rp.log` | nama restore point (mulai byte offset 16) + timestamp 64-bit FILETIME (8 byte terakhir) |
| `change.log{.x}` | log perubahan file yang dipantau; file lama disalin ke sana dengan nama `Axxxxxxx.ext` |
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore` | konfigurasi: `RPSessionInterval`, `DisableSR` (1 = fitur dimatikan) |

Nilai forensik: file hive Registry versi lama, `NTUSER` lama, dan file aplikasi yang di-revert — sering jadi sumber perbandingan "sebelum insiden" ketika host overwrite tidak menyimpan kondisi sebelumnya.

### Thumbnail & Icon Cache / Cache Gambar Kecil

`%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db` menyimpan thumbnail file gambar (Vista ke atas; XP memakai `Thumbs.db` per folder). DB ini memuat nama file asal, metadata waktu, dan bisa mengekstrak gambar kecil dari file yang sudah dihapus — sehingga sering menjadi satu-satunya bukti grafis yang tersimpan. Gunakan Thumbcache Viewer atau Thumbs Viewer untuk ekstraksi.

### Metadata File: EXIF, PDF, OLE / File Metadata

- **Gambar JPEG** membawa EXIF: model & serial kamera, timestamp, kadang koordinat GPS. Ekspor dengan `exiftool` atau `exiv2`. Ingat EXIF mudah dipalsukan — verifikasi dengan artefak lain.
- **PDF** membawa producer aplikasi, nama author, dan tanggal (misalnya saat dokumen Word dikonversi ke PDF terlihat jejak asalnya). Ekspor dengan `pdfinfo` atau `exiftool`.
- **Office (OLE)** dapat menyimpan template, author terakhir revisi, dan daftar hingga 10 penulis sebelumnya via `Document Inspector` (File > Info > Check for Issues) atau tool exiftool/OleTools.

### Database ESE / ESE Databases

Banyak fitur Windows menyimpan data di Extensible Storage Engine (JET Blue, `.edb`/`.dat`). Yang paling penting:

| File | Isi |
|---|---|
| `Windows.edb` / `Windows.db` | indeks pencarian Windows — `C:\ProgramData\Microsoft\Search\Data\Applications\Windows` |
| `WebCacheV24.dat` / `WebCacheV01.dat` | cache, history, cookie IE/Edge – `%LOCALAPPDATA%\Microsoft\Windows\WebCache` |
| `contacts.edb`, `WLCalendarStore.edb` | kontak & kalender Live Mail |
| `spartan.edb` | favourites Edge legacy |
| `DataStore.edb` | metadata Windows Update — `C:\Windows\SoftwareDistribution\DataStore` |
| `SRUDB.dat` | SRUM — semua aktivitas resource (dibahas di bagian SRUM) |
| `Mailbox Database.edb` | database mail Exchange |

Parsing: ESEDatabaseView (NirSoft, GUI + ekspor CSV/HTML/XML), `libesedb`/`esentutl` (CLI), atau tool khusus (SrumECmd). Indeks pencarian `Windows.edb` khusus berharga: menjawab "istilah apa yang pernah dicari user" walau file aslinya sudah dihapus.

### Artefak Browser / Browser Artifacts

| Browser | Cache | Cookies | History |
|---|---|---|---|
| Firefox | `%LOCALAPPDATA%\Mozilla\Firefox\...\cache2` | `cookies.sqlite` | `places.sqlite` |
| Chrome | `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache` | `Network\Cookies` (SQLite) | `History` (SQLite) |
| Edge modern | pola sama dengan Chrome | pola sama | pola sama |
| IE / Edge legacy | `WebCacheV01.dat` | `WebCacheV01.dat` | `WebCacheV01.dat` |

NirSoft menyediakan kumpulan viewer satu-klik: MZCacheView/MZCookiesView/MZHistoryView (Firefox), ChromeCacheView/ChromeCookiesView/ChromeHistoryView, IECacheView, EdgeCookiesView, dan BrowsingHistoryView yang mencocokkan sejarah semua browser di satu tabel. Untuk Firefox modern, `Hindsight` (parser SQLite) juga berguna.

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
- [ ] Artefak USB diperiksa: USBSTOR, DeviceClasses, MountedDevices, USBDeview.
- [ ] Prefetch Parameter (EnablePrefetcher) dan keystroke MRU/UserAssist diekstrak.
- [ ] Restore point dan Volume Shadow Copy diselidiki bila fiturnya aktif.
- [ ] Arsitektur browsing: cache/cookies/history browser dianalisis saat kasus browsing.
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

## USBSTOR & MountedDevices / USB Deep-Dive

Ketika flash disk yang sama dipasang lalu dicabut, pasangan key berikut memberi gambaran perangkat apa yang pernah terhubung:

```cmd
reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR" /s | findstr /i "Disk&Ven"
reg query "HKLM\SYSTEM\MountedDevices"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceClasses" /s | findstr /i "53f56307"
```

| Key | Makna |
|---|---|
| `Enum\USBSTOR\Disk&Ven_<pabrikan>&Prod_<produk>&Rev_<x>&<serial>` | device class + serial unik; dibaca PnP Manager dari device descriptor |
| `Control\DeviceClasses\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}` | GUID interface **disk**; LastWrite key = waktu unit disk terakhir terhubung |
| `Control\DeviceClasses\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}` | GUID interface **volume**; kuncinya memuat `ParentIdPrefix` yang sama |
| `SYSTEM\MountedDevices` | pemetaan device → huruf drive (`\DosDevices\F:`), data tipenya binary |
| `setupapi.dev.log` | log instalasi driver device — melengkapi kronologi pertama kali device terlihat |

Kelemahannya: LastWrite key berdiri sendiri hanya menunjukkan koneksi terakhir, bukan jumlah sebelumnya. Gunakan USBDeview (NirSoft) atau DevCon untuk menggabungkan, lalu koordinasi dengan LNK/jump lists dan MountedDevices untuk timeline.

## UserAssist & Daftar MRU / UserAssist & MRU Lists

Key `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{GUID}\Count` mencatat program yang dijalankan melalui Explorer (shortcut, exe terlihat pada desktop/Start menu) sebagai nilai berenkode ROT-13, lengkap dengan run count, focus time, dan waktu terakhir dieksekusi. Gunakan `UserAssistView` atau `RECmd` untuk decoding otomatis.

MRU lainnya yang umum dipakai:

| Key di bawah `HKCU\...\Explorer` | Isi |
|---|---|
| `RecentDocs` | file yang dibuka via shell + `MRUListEx` urutan akses |
| `ComDlg32\OpenSavePidlMRU` | file yang dibuka/disimpan via **Open/Save dialog** dibagi per ekstensi |
| `ComDlg32\LastVisitedPidlMRU` | aplikasi yang dipakai untuk dialog open/save terakhir |
| `RunMRU` | apa yang diketik di kotak Run |
| `TypedURLs` | URL yang diketik manual di address bar (IE) |
| `FileExts` | aplikasi yang dipilih user untuk ekstensi tertentu (`OpenWithList`) |
| `MountPoints2` | drive network/USB berdasarkan UNC atau GUID |
| `Map Network Drive MRU` | mesin/drive yang dipetakan manual user |

## Lokasi Autostart / Startup Locations

Pemetaan lokasi autostart paling sering dipakai penyusup:

| Lokasi | Kapan dijalankan | Catat |
|---|---|---|
| `HKLM\...\CurrentVersion\Run` | startup semua user | paling dikenal, wajib dicek |
| `HKCU\...\CurrentVersion\Run` | startup user bersangkutan | idem |
| `HKLM / HKCU ...\RunOnce` | sekali berjalan lalu value dihapus | dipadamkan setelah run |
| `Winlogon\Shell` & `Userinit` | saat logon | shell default `explorer.exe`; ganti = suspicious |
| `Policies\Explorer\Run` | startup | sering dipakai penyusup untuk menyembunyikan autostart |
| `Session Manager\BootExecute` | sebelum Windows dimuat | program boot-time (mis. `autochk`); value berubah = patut dicurigai |
| `Services` dengan `Start=2` | autostart service | driver & service backdoor |
| `HKCU\Control Panel\Desktop\SCRNSAVE.EXE` | saat screensaver aktif | path tak wajar = peluang persistence |
| `Shell Folders` / `User\Common Startup` | startup folder | item shortcut di `%APPDATA%`/`%ALLUSERSPROFILE%` Start Menu |

Setelah registry, jangan berhenti: scheduled task (`schtasks /query /fo LIST /v`) dan WMI event subscription (`__EventConsumer`) adalah dua mekanisme persistence modern yang tidak tampak di Run key. Gunakan Autoruns / `Autorunsc -a` (Sysinternals) atau Silent Runners untuk pemindaian menyeluruh; integrasi VirusTotal di Autorunsc opsional untuk memeriksa hash executable mencurigakan.

## References / Referensi

1. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. MITRE ATT&CK — https://attack.mitre.org/
3. SANS DFIR posters (Windows artifacts, publik) — https://digital-forensics.sans.org/posters
4. libforensics Windows forensic artifacts (public availability) — https://github.com/kostaz/libforensics
5. NirSoft Freeware (prefetch, ESE, browser, USB, MRU viewers) — https://www.nirsoft.net/
6. Eric Zimmerman tools (EZ tools: RECmd, PECmd, SrumECmd) — https://ericzimmerman.github.io/
7. Sysinternals Suite (Autoruns, PsTools, Process Explorer, Handle, ListDLLs) — https://learn.microsoft.com/sysinternals/

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
