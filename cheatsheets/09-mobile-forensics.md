# Mobile Forensics Cheatsheet / Cheatsheet Forensik Mobile

> **TL;DR**: Pendekatan praktis forensik mobile — isolasi perangkat, path ADB untuk Android, struktur backup iOS, dan parsing aplikasi populer (WhatsApp, Chrome) — dengan perhatian pada enkripsi dan chain of custody.

## Overview / Gambaran Umum

Forensik mobile menantang karena tiga hal: data terenkripsi secara default, perangkat modern sulit dibongkar lewat software, dan aplikasi cepat mensinkronisasi ke cloud — sekali sinkron berjalan, data lokal bisa berubah. Karena itu urutan tindakan penting: isolate → capture state → acquire → parse.

Untuk Android, jalur yang umum: adb untuk menarik data app (butuh root untuk data app penuh), `adb backup` untuk aplikasi tertentu, dan software akuisisi khusus bila perlu. Untuk iOS, jalurnya: backup via libimobiledevice (idevicebackup2), lalu database aplikasi (WhatsApp, Chrome History) di-parse dari file backup tersebut.

Tool komersial (Cellebrite UFED, Magnet AXIOM) memberi kemampuan lebih (chip-off, bypass lock) — repo ini hanya menyimpulkan konsep; untuk command detail kita pakai tool open-source dan dokumentasi resmi.

## Key Concepts / Konsep Kunci

### Isolasi Perangkat / Device Isolation

- Aktifkan **airplane mode** — matikan koneksi seluler/Wi-Fi secepatnya; sinkronisasi cloud bisa mengubah data sebelum sempat diperiksa.
- Bila kasus sensitif, gunakan Faraday bag (kantong anti-sinyal) untuk menjaga perangkat tetap terisolasi.
- Catat state baterai & kondisi fisik di CoC; foto layar bila diakses.

### Android Acquisition / Akuisisi Android

- **ADB (Android Debug Bridge)** — tool resmi; satu mode: device harus USB-debugging. Semua app pull: `adb backup`, dan root bila butuh `data/data`.
- Full-system image butuh root dan `dd` di partisi data.
- **`adb shell getprop`** — serangkaian info perangkat; catat ke CoC sebagai deskripsi.

### iOS Acquisition / Akuisisi iOS

- **libimobiledevice (idevicebackup2)** — backup lokal tanpa jailbreak; data di backup dalam bentuk plist + sqlite.
- Password & konten terenkripsi kadang tidak ikut pada backup tanpa enkripsi; pastikan pemahaman versi iOS terhadap batas backup sebelum menarik kesimpulan.

## Commands / Perintah

### Android (ADB)

```bash
# Status & identitas device
adb devices -l
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model

# Backup aplikasi + shared storage
adb backup -apk -shared -all -f backup.ab

# Log sistem saat itu
adb logcat -d > logcat.txt
adb shell dumpsys > dumpsys.txt

# Daftar package
adb shell pm list packages -f

# Rooted: ekstrak data app & WhatsApp sqlite
# adb shell su -c "cp /data/data/com.whatsapp/databases/msgstore.db /sdcard/"
# adb pull /sdcard/msgstore.db

# Screenshot & kondisi
adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png
```

### iOS (libimobiledevice)

```bash
# Backup perangkat (tanpa jailbreak)
idevicebackup2 backup /path/to/backup

# Parse informasi device
ideviceinfo
idevice_id -l

# Lokasi artefak di backup (contoh):
#   WhatsApp    -> AppDomain-com.whatsapp (sqlite msgstore)
#   Chrome      -> AppDomain-Chrome History (sqlite)
#   Messages    -> Library/SMS/sms.db (iMessage)
```

## Workflow / Alur Kerja

1. **Isolasi** — airplane mode atau Faraday; catat waktu & state daya di CoC.
2. **Dokumentasi** — foto kondisi, model, SN, IMEI (bila terlihat), versi OS.
3. **State awal** — logcat/dumpsys untuk Android; `ideviceinfo` untuk iOS — catat versi & status.
4. **Acquire** — ADB backup atau rooted pull untuk Android; idevicebackup2 untuk iOS.
5. **Parsing** — parse sqlite di host (sqlite3 / Python); WhatsApp `msgstore.db` dan Chrome History adalah dua entitas yang umum.
6. **Laporan** — temuan utama: contact terkait, waktu aktivitas, pesan-location; rujuk sesuai CoC.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Tidak mengisolasi perangkat** — sinkronisasi cloud berjalan dan mengubah data lokal sebelum sempat diperiksa.
- ⚠️ **Backup tanpa password** — bisa menghasilkan data yang terenkripsi butuh; catat password bila user memberikan.
- ⚠️ **Tidak memastikan versi ADB / platform-tools** — beberapa command hanya valid di platform-tools terbaru.
- ⚠️ **Memulai sentence dengan assumption rootedців** — bila device tidak rooted, banyak data tidak terget; gunakan alternatif (sdcard paths, backup).
- ⚠️ **Tidak mencatat raw output parsing** — bila db gigabyte, tanpa raw output temuan tidak bisa direproduksi.

## Cross-references / Referensi Silang

- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — akuisisi image secara bit-stream.
- [01 Chain of Custody](../cheatsheets/01-chain-of-custody.md) — dokumentasi perangkat & hash.
- [`tools/mobile/adb-forensics.sh`](../tools/mobile/adb-forensics.sh) — oneliner ADB.

## Studi Kasus: WhatsApp / Worked Example

Sebuah kasus melibatkan perangkat Android yang diduga dipakai untuk komunikasi terkait insiden. Tujuannya: membuktikan apakah akun tertentu mengirim pesan pada rentang waktu tertentu. Perangkat disita dalam keadaan menyala.

Langkah pertama adalah isolasi. Perangkat diaktifkan mode pesawat, lalu dimasukkan ke kantong anti-sinyal. Waktu, kondisi baterai, dan model perangkat dicatat di form chain of custody. Langkah kedua adalah dokumentasi: foto layar, catat IMEI, dan versi Android dari menu pengaturan.

Langkah ketiga adalah akuisisi. Karena perangkat tidak di-root, tim memakai `adb backup` untuk aplikasi yang mengizinkan backup, lalu menarik data yang tersedia di shared storage. Aplikasi chat biasanya menyimpan database di direktori privat yang tidak ikut backup tanpa root, sehingga tim mencatat keterbatasan ini.

Langkah keempat adalah parsing. Database WhatsApp (`msgstore.db`) dibuka dengan `sqlite3`, lalu tabel pesan diekspor ke CSV. Tim memfilter berdasarkan rentang waktu dan JID lawan bicara. Untuk pesan yang sudah dihapus, tim memeriksa apakah database lama (`msgstore-YYYY-MM-DD.1.db.crypt`) masih tersedia; file terenkripsi ini membutuhkan kunci dari perangkat.

Langkah kelima adalah korelasi. Tim mencocokkan timestamp pesan dengan log panggilan, riwayat lokasi, dan aktivitas akun lain di perangkat. Hasilnya bukan hanya daftar pesan, tetapi kronologi yang bisa dipertanggungjawabkan. Semua langkah, termasuk kegagalan mendapatkan data tanpa root, ditulis di bagian limitations.

## Parsing Database Aplikasi / App Database Parsing

Database aplikasi mobile umumnya SQLite. Beberapa yang sering muncul:

| Aplikasi | File | Isi penting |
|---|---|---|
| WhatsApp | `msgstore.db` | pesan, waktu, JID |
| Telegram | `cache4.db` | pesan dan metadata chat |
| Signal | `signal.db` | pesan terenkripsi, metadata |
| Chrome | `History` | URL dan waktu kunjungan |
| Gmail | `mailstore` | metadata email |

Langkah parsing yang aman: salin database beserta file `-wal` dan `-shm` (jika ada), lalu buka salinannya. Jangan membuka database langsung di lokasi asli, karena SQLite dapat menulis ke file journal. Gunakan query baca-saja (`PRAGMA query_only = ON;`) untuk berjaga-jaga.

Ekspor hasil query ke CSV dan simpan bersama hash database asal. Catat versi aplikasi dan versi SQLite, karena skema database berubah antar versi. Jika skema tidak dikenali, gunakan dokumentasi komunitas atau tool parsing khusus, dan sebutkan tool tersebut di laporan.

## Checklist Forensik Mobile / Mobile Forensics Checklist

- [ ] Perangkat diisolasi (mode pesawat atau Faraday).
- [ ] Kondisi fisik, model, dan versi OS dicatat.
- [ ] Waktu UTC pencatatan dan akuisisi dicatat.
- [ ] Metode akuisisi dicatat (ADB backup, root, tool khusus).
- [ ] Hash hasil akuisisi dihitung dan disimpan.
- [ ] Database aplikasi disalin bersama file pendampingnya.
- [ ] Parsing dilakukan pada salinan, bukan file asli.
- [ ] Keterbatasan (tanpa root, enkripsi) ditulis di laporan.

## Pertanyaan Umum / FAQ

**Apakah ADB backup masih bisa dipakai?** Pada Android versi baru, banyak aplikasi menolak backup atau fitur ini dibatasi. Periksa hasil backup dan jangan mengasumsikan semua data ikut. Alternatifnya adalah akses root atau tool akuisisi khusus.

**Bagaimana jika perangkat terkunci?** Tanpa kredensial, akuisisi penuh biasanya tidak mungkin. Fokus pada data yang bisa diakses, dokumentasikan keterbatasan, dan pertimbangkan bantuan vendor forensik resmi bila kasus membutuhkan.

**Apakah data cloud termasuk lingkup?** Bisa, tetapi memerlukan izin dan koordinasi dengan penyedia layanan. Data cloud juga punya timestamp berbeda dari perangkat, sehingga perlu dinormalisasi.

## Struktur Backup iOS / iOS Backup Internals

Backup iOS dari libimobiledevice menghasilkan direktori berisi ribuan file dengan nama hash. Struktur intinya: `Manifest.db` (database SQLite yang memetakan nama file asli ke nama hash), `Manifest.plist` (metadata perangkat dan daftar aplikasi), serta file data itu sendiri. Tanpa `Manifest.db`, file backup sulit dipetakan kembali ke aplikasi asalnya.

Langkah parsing yang lazim:

1. Buka `Manifest.db` dan baca tabel `Files` (kolom `fileID`, `domain`, `relativePath`, `flags`).
2. Cari domain aplikasi yang relevan, mis. `AppDomain-com.whatsapp` atau `HomeDomain`.
3. Petakan `fileID` ke file fisik: dua karakter pertama `fileID` membentuk nama subdirektori.
4. Salin file target dan buka sebagai SQLite atau plist sesuai jenisnya.

Jika backup dienkripsi, beberapa file hanya bisa dibaca setelah kunci tersedia. Backup terenkripsi justru sering memuat lebih banyak data (mis. keychain dan data aplikasi yang dilindungi), sehingga bila pengguna memberikan kata sandi, gunakan backup terenkripsi.

Catat versi iOS dan versi libimobiledevice di laporan. Perbedaan versi bisa memengaruhi domain dan struktur file. Jangan mengandalkan nama file untuk menyimpulkan isi; verifikasi dengan skema database di dalamnya.

## Tool Komersial vs Open Source / Tooling Trade-offs

Tool komersial seperti Cellebrite UFED dan Magnet AXIOM menawarkan dukungan perangkat yang lebih luas, termasuk model dengan bootloader terkunci dan akuisisi tingkat chip. Namun biayanya tinggi dan metodenya tertutup, sehingga hasil sulit diverifikasi secara independen.

Pendekatan open-source (ADB, libimobiledevice, parsing SQLite manual) lebih transparan dan bisa direproduksi, tetapi cakupannya terbatas pada perangkat yang mengizinkan akses. Banyak laboratorium memakai keduanya: tool komersial untuk akuisisi, open-source untuk verifikasi dan parsing.

Apa pun tool yang dipakai, prinsipnya sama: catat versi, metode, dan hash hasil. Laporan yang menyebut "dianalisis dengan tool X versi Y" jauh lebih kuat daripada laporan yang hanya menyebut nama tool tanpa versi.

## References / Referensi

1. Android Developer ADB Documentation — https://developer.android.com/tools/adb
2. libimobiledevice — https://libimobiledevice.org/
3. NIST SP 800-101 — Guidelines on Mobile Forensics (public overview) — https://csrc.nist.gov/pubs/sp/800/101/r1/final
4. RFC 3227 — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
