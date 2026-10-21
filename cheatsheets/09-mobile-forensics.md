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

## References / Referensi

1. Android Developer ADB Documentation — https://developer.android.com/tools/adb
2. libimobiledevice — https://libimobiledevice.org/
3. NIST SP 800-101 — Guidelines on Mobile Forensics (public overview) — https://csrc.nist.gov/pubs/sp/800/101/r1/final
4. RFC 3227 — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
