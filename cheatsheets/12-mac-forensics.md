# Mac Forensics Cheatsheet / Cheatsheet Forensik macOS

> **TL;DR**: Artefak macOS bernilai investigasi berada di empat tempat utama: plist (preferensi & browser), Spotlight `store.db`, data aplikasi bawaan (Safari, Mail, iChat, Keychain), serta log di `/var/log` dan `~/Library/Logs`. Alur tipikal: image dengan write blocker → petakan diri /Users → ekstrak plist & Spotlight → bangun timeline dari MAC time + aplikasi history.

## Overview / Gambaran Umum

macOS adalah sistem berbasis Unix yang bergantung pada dua lapis kernel — Mach dan BSD. Pertumbuhan pemakaiannya menjadikan Mac target yang makin menarik; dampaknya diperbesar karena alat keamanan untuk mac lebih sedikit dibanding platform lain. Investigasi memerlukan bukti berupa perangkat lunak jahat di dalam sistem, percobaan login yang tidak sah, dan koneksi ke server atau situs berbahaya — semuanya tersimpan di file log, direktori konfigurasi, dan riwayat aplikasi. Tugas investigator: ekstrak sumber-sumber itu dan susun jadi timeline.

Pekerjaan harus dilakukan di image, bukan di device asli: seize dulu, image dengan write blocker, lalu analisis salinan. Untuk itulah pemahaman atas filesystem (APFS), struktur direktori, dan library tiap user menjadi prasyarat.

## Key Concepts / Konsep Kunci

### APFS / Apple File System

APFS memisahkan dua lapis:

- **Container layer** — metadata volume, status enkripsi, snapshot volume.
- **File system layer** — metadata file, isi file, struktur direktori.

Informasi file dan event disk direpresentasikan sebagai token berstruktur biner. Tools pemindai APFS umumnya membaca kedua lapis itu sehingga hardlink dan file hasil clone tetap terpetakan benar.

### Property List / plist

Preferensi user dan aplikasi disimpan sebagai plist. Format datanya Core Foundation: CFString, CFNumber, CFBoolean, CFDate, CFData, CFArray, CFDictionary — dan bisa tersimpan dalam XML maupun binary. Nilai kunci yang sering jadi bukti: History.plist, Downloads.plist, Bookmarks.plist (Safari), com.apple.airport.preferences.plist (WiFi), com.apple.iPod.plist (iDevice yang pernah terhubung), Accounts3.sqlite (akun sosial).

### Account & BSM

Data akun (UID, kebijakan password, status administrator/guest) per user ada di `/Users/<username>/Library`. Bila Basic Security Module (BSM) aktif, catatan audit menyimpan atribut per event: argumen program, return value, data teks, socket, eksekusi file — dari sini tipe file, pembuatnya, dan pola pemakaiannya bisa direkonstruksi.

## Data Aplikasi yang Bernilai / Application Data of Value

| Sumber | Lokasi & kenapa penting |
|---|---|
| Finder | Aplikasi bawaan untuk menjelajah file; preferensinya bisa dipertahankan di plist |
| Versi sistem | `/System/Library/CoreServices/SystemVersion.plist` — memastikan image berasal dari OS yang sesuai |
| Statistik & MAC time | `stat` (mis. `stat -x <file>`) menampilkan waktu modification/access/change per file — bahan utama timeline |
| Application bundles | Direktori data aplikasi yang tersembunyi dari user; ingin dicek kode eksekusinya bila dianggap malware |
| Safari | `/Users/<u>/Library/Safari` — `History.plist`, `Downloads.plist`, `Bookmarks.plist` |
| Mail | `/Users/<u>/Library/Mail` — email disimpan per file dalam format `.emlx` (ASCII), bisa diurai dengan ekstraktor email |
| iChat | Tidak menyimpan percakapan otomatis; bila user memilih menyimpan: `/Users/<u>/Documents/iChats` — per file `<username> on <date> at <time>.ichat` |
| Keychain | Password manager bawaan: kredensial web, WiFi, SSH. Isi dienkripsi (3DES) dan hanya terbuka dengan master password — pola password user sering terungkap dari sini |
| Spotlight | `store.db` per partisi, di `/.Spotlight-V100/Store-V2/<UUID>` — indeks metadata semua file (MAC time, jumlah dibuka) — dibahas di bawah |
| Time Machine | Backup menyimpan BackupAlias berisi info biner disk sumber; siklus backup lama bisa memuat file yang sudah dihapus dari disk aktif |
| Kext (kernel extensions) | Modul kernel yang bisa memodifikasi jaringan (memblokir/mengubah/menyadap paket); audit mereka yang ada dengan mencari koneksi mencurigakan |
| Home directory | `/Users/<u>` menyimpan auth data (percobaan login sukses dan gagal), aplikasi & instalasi; periksa ± desktop/documents/library |

## Mac Log Files / Log macOS

| Log | Isi |
|---|---|
| `/var/log/*` | Folder induk log sistem — mulai dari sini |
| `/var/audit/*` | Log audit (BSM) |
| `/var/log/install.log` | Tanggal instalasi sistem & update software |
| `/var/log/crashreporter.log` | Riwayat crash aplikasi |
| `/var/log/cups/access_log`, `error_log` | Koneksi printer |
| `/var/log/daily.out` | Riwayat antarmuka jaringan |
| `/var/log/samba/log.nmbd` | Koneksi ke/dari mesin Windows via Samba |
| `~/Library/Logs` | Log aplikasi tingkat user |
| `~/Library/Logs/iChatConnectionErrors` | Kegagalan koneksi iChat |
| `~/Library/Logs/Sync` | Sinkronisasi device .Mac/iCloud |

## Mac Directories yang Sering Diperlukan / Mac Directories

| Yang dicari | Lokasi |
|---|---|
| Launch agents (per user/per sistem) | `/Library/LaunchAgents/*`, `/System/Library/LaunchAgents/*` |
| Launch daemons | `/Library/LaunchDaemons/*`, `/System/Library/LaunchDaemons/*` |
| Startup items | `/Library/StartupItems/*`, `/System/Library/StartupItems/*` |
| Cron jobs | `/usr/lib/cron/jobs/*`, `/etc/crontab`, `/usr/lib/cron/tabs/*` |
| Jaringan WiFi tersimpan | `/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist` |
| Preferensi aplikasi per user | `/Users/<u>/Library/Preferences/*` |
| iDevice yang terhubung | `/Users/<u>/Library/Preferences/com.apple.iPod.plist` |
| Akun sosial | `/Users/<u>/Library/Accounts/Accounts3.sqlite` |
| Trash | `/Users/<u>/.Trash/` |
| Safari / Firefox / Chrome | `/Users/<u>/Library/Safari/*`; `/Users/<u>/Library/Application Support/Firefox/*`; `…/Google/Chrome/*` |

Lokasi autostart di atas adalah padanan Mac dari katalog persistence di [07 Windows Artifacts](07-windows-artifacts.md). Entri di LaunchAgents/LaunchDaemons/StartupItems biasanya dibuat aplikasi atau admin — entri baru tanpa alasan layak dicatat sebagai temuan.

## Commands / Perintah

```bash
# === Versi sistem ===
plutil -p /System/Library/CoreServices/SystemVersion.plist   # baca plist (bisa juga: plutil -convert xml1)

# === Timeline per file ===
stat -x /Users/<u>/Library/Safari/History.plist              # MAC time satu file

# === Preferensi browser & WiFi ===
plutil -p /Users/<u>/Library/Safari/History.plist
plutil -p /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist

# === Autostart ===
ls -la /Library/LaunchAgents /Library/LaunchDaemons /Library/StartupItems 2>/dev/null
cat /etc/crontab 2>/dev/null; ls /usr/lib/cron/tabs/ 2>/dev/null

# === Riwayat shell ===
tail ~/.bash_history      # command terakhir di mesin tersangka

# === Email .emlx ===
# file emlx perlu direformat atas teks ASCII per pesan; grep pola header Subject/MIME
grep -l "Subject:" /Users/<u>/Library/Mail/**/* -r 2>/dev/null
```

Perhatikan perilaku `stat` di Mac (BSD) berbeda dari versi GNU: gunakan `-x` untuk output UNIX sederhana, dan normalisasi zona waktu sebelum mencatat ke timeline.

## Spotlight Parsing / Parsing store.db

Spotlight mengindeks semua file pada disk dan menyimpannya ke database sentral. Setiap partisi Mac punya file `store.db` sendiri di path tersembunyi `/.Spotlight-V100/Store-V2/<UUID>`. Isinya bermakna buat investigator: MAC time per file, "last opened", jumlah kali file/aplikasi dibuka, plus metadata turunan (width/height gambar, jenis dokumen).

Untuk parsing, gunakan script Python yang menerima database dan folder output:

```bash
python spotlight_parser.py <path_ke_store.db> <folder_output>
```

Output tersusun dua buah: file teks berisi dump semua entri (atribut `kMDItem*`: tanggal dibuat/ditambah/terakhir dipakai, nama tampilan, tipe konten), dan file CSV berisi daftar direktori/file per partisi. Dengan data itu bisa dicari file yang dibuka pada rentang waktu tertentu, file yang di-clone, dan jejak aplikasi yang pernah membaca file yang aslinya sudah dihapus.

Sifat khusus: database Spotlight bisa ter-encode kompresi block (software parser mem-dekode kompresi internal). Belum semua versi macOS didukung parser publik — uji parser pada store.db versi yang sama dulu.

## APFS Analysis / Analisis APFS

Untuk disk APFS, gunakan tool khusus yang membaca format ini, mis. Biskus APFS Capture:

- Mendeteksi seluruh partisi di disk fisik maupun image dan menuliskannya ke file report.
- Dua bentuk laporan: CSV (metadata tiap file/folder, siap filter) dan SQLite (struktur metadata yang diatur seperti di APFS, termasuk akses per key/inode/xattr/extent dengan CNID dan nomor block).
- Menyediakan pencarian file dinamis melalui hardlink dan konten file hasil clone.

Sebelum dipakai untuk kasus nyata, pastikan image tetap read-only dan simpan hasil report sebagai artefak kasus, bukan perubahan dari sumber.

## Workflow / Alur Kerja

1. **Aman & image** — seize device, image dengan write blocker, kerjakan salinan; catat status FileVault/encryption di awal.
2. **Peta user & wadah** — petakan `/Users` dan `~/Library` tiap user; gunakan tabel di atas sebagai daftar periksa.
3. **Autostart & persistence** — LaunchAgents/Daemons/StartupItems, cron, dan airport preferences.
4. **Aplikasi utama** — Safari (History/Downloads/Bookmarks), Mail (.emlx), iChat (jika user menyimpan), akun (Accounts3.sqlite).
5. **Spotlight & Time Machine** — parse `store.db` untuk riwayat pemakaian; bila backup tersedia, bandingkan snapshot lama dengan disk aktif untuk melihat file yang sudah dihapus.
6. **Log & audit** — masuk `/var/log`, `~/Library/Logs`, dan `/var/audit` bila tersedia; kumpulkan event janggal dan koneksi.
7. **Timeline & korelasi** — gabungkan MAC time + log + riwayat aplikasi ke satu rentang UTC, dokumentasikan dengan EV-ID.

## Common Pitfalls / Kesalahan Umum

- **FileVault aktif** — volume terenkripsi tidak bisa diparse sebelum dibuka kunci; kuncinya bisa ada di Keychain atau akun iCloud. Catat status enkripsi di awal; pengambilan kunci hanya boleh melalui otorisasi yang sah.
- **Plist binary vs XML** — tidak semuanya bisa dibaca sebagai teks biasa; `plutil -p` (atau konversi ke XML dulu) menangani keduanya.
- **Spotlight store.db per partisi** — lupa partisi kedua atau store tersembunyi bisa merusak coverage.
- **iChat tidak otomatis** — keberadaan file di `~/Documents/iChats` berarti user memilih menyimpan manual, bukan artefak default.
- **Kext networking** — modul jaringan bisa menyadap atau mengubah trafik; daftar kext terinstal dan cari koneksi janggal.
- **Trash** — file di `~/.Trash/` sering masih utuh dan layak diperiksa, tetapi tidak menandai kapan penghapusannya; andalkan timestamp filesystem untuk menaruhnya di timeline.
- **Kompatibilitas parser** — uji parser Spotlight/APFS yang dipakai terhadap output versi macOS yang sama sebelum menarik kesimpulan.

## Cross-references / Referensi Silang

- [02 Evidence Acquisition](02-evidence-acquisition.md) — teknik image & write blocker.
- [04 Disk Forensics](04-disk-forensics.md) — konsep filesystem umum (termasuk HFS+ era lama).
- [05 Memory Forensics](05-memory-forensics.md) — Volatility juga bisa dipakai untuk dump Mac.
- [08 Linux Artifacts](08-linux-artifacts.md) — lingkungan Unix yang sejajar; padankan perintah antara Linux dan Mac sesuai konteksnya.

## Checklist Artefak Mac / Mac Artifact Checklist

- [ ] Image dengan write blocker; status FileVault dicatat.
- [ ] `/Users/<u>/Library` dipetakan; Preferences & Accounts diperiksa.
- [ ] Safari History/Downloads/Bookmarks di-ekstrak.
- [ ] Mail (.emlx), iChat, dan Keychain dicek (dekripsi Keychain hanya bila otorisasi memungkinkan).
- [ ] LaunchAgents, LaunchDaemons, StartupItems, dan cron diperiksa.
- [ ] `store.db` (semua partisi) diparse; entri "terakhir dipakai" adalah Новости timeline yang kuat.
- [ ] `/var/log`, `~/Library/Logs`, `/var/audit` dikumpulkan & dicatat.
- [ ] iDevice plist & Time Machine backup diperiksa bila tersedia.
- [ ] Timeline dinormalisasi UTC dan setiap temuan dirujuk ke EV-ID.

## Studi Kasus: Exfiltration via Mail / Worked Example

Di sebuah kantor, terdapat kecuran bahwa seorang karyawan mengirim data proyek via Mail. Image diambil; analisis dimulai dari `/Users/<karyawan>/Library/Mail`: file `.emlx` dipilah menurut header Subject dan To. Beberapa pesan besar ke domain luar terdeteksi — attachment-nya cocok dengan file proyek milik user tersebut.

Timeline dibangun dari Spotlight store.db: Mail dibuka sekitar pukul 14.00, file xlsx dibuka pukul 13.56, dan folder Dropbox diakses pukul 13.58. Keychain user memuat kredensial mailbox eksternal; `com.apple.airport.preferences.plist` menunjukkan hotspot bernama(+ MAC address) yang tidak dikenal dipakai pada jam yang sama.

Log `~/Library/Logs/iChatConnectionErrors` memperlihatkan beberapa kegagalan koneksi ke domain yang tidak dikenal; Time Machine lama punya snapshot dengan file proyek yang setelah insiden terhapus. Kombinasi temuan itu memperkuat hipotesis eksfiltrasi.

Laporan akhir menautkan semua temuan dengan EV-ID per artefak (plist, log, mailbox .emlx) dan menandai bagian yang masih dugaan, sehingga pembaca tahu mana fakta dan mana inferensi.

## Mac Forensics Tools / Alat Mac

| Tool | Fungsi | Sumber |
|---|---|---|
| OS X Auditor | Parse & hash artefak dari sistem yang jalan/salinan, tanpa mengubah bukti | github (open source) |
| Recon Imager (Sumuri) | Bootable imaging: disk fisik, volume, dan RAM tanpa password admin; deteksi container APFS, FileVault, Fusion/Core Storage | sumuri.com |
| Memoryze for Mac (FireEye) | Akuisisi/analisis memori Mac, live maupun offline image | fireeye.com |
| Mac OS X Memory Analysis Toolkit | Toolkit Python untuk investigasi Mac/BSD, mencari artefak malware tertentu | github (open source) |
| Volatility | Kerangka analisis RAM Mac/Linux/Windows — analisis live state lewat data volatile | volatilityfoundation.org |
| F-Response | Akses read-only via IP ke disk fisik, RAM, cloud/email/database dari remote | f-response.com |
| Stellar Data Recovery Professional for Mac | Recovery data hilang dari APFS/HFS+/exFAT/NTFS, termasuk Mac yang crash/non-boot | stellarinfo.com |
| OS X Rootkit Hunter | Scanner rootkit, backdoor, dan local exploit Mac | cnet download |
| Biskus APFS Capture | Parse metadata APFS (CSV/SQLite, hardlink, clone) | dok vendor |

Pilihan alat bergantung pada tujuan: untuk image → Recon Imager; untuk RAM → Memoryze/Volatility; untuk struktur APFS → parser khusus; untuk triage cepat → OS X Auditor.

## References / Referensi

1. Apple File System Guide — https://developer.apple.com/documentation/foundation/file_system/about_apple_file_system
2. Spotlight internals (tulisan publik) — https://eclecticlight.co/2018/10/05/how-spotlight-works-and-how-to-create-and-query-a-spotlight-database/
3. macOS system log structure — https://www.logit.io/knowledge-base/mac-os-log-collection/
4. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-22 · **Maintained by**: @cingmen
