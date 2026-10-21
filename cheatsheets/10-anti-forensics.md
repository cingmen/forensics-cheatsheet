# Anti-Forensics Cheatsheet / Cheatsheet Anti-Forensik

> **TL;DR**: Teknik anti-forensik yang umum — timestomping, steganografi, log wiping, enkrpisi, dan wiping aman — beserta cara mendeteksinya: anomali timestamps, USN journal, entropi, dan korelasi multi-sumber.

## Overview / Gambaran Umum

Anti-forensik adalah teknik yang dipakai penyerang untuk mempersulit investigasi: menghapus jejak, memanipulasi timestamps, menyembunyikan data di file media (steganografi), atau mengacak-acak log. Investigator modern tidak boleh menganggap semua artefak jujur — karena itu deteksi anti-forensik berdiri di atas korelasi multi-sumber, bukan satu sumber.

Polanya bermacam: timestamps memori disk bisa dimanipulasi (timestomping), log bisa dihapus atau dibersihkan (log wiping), data bisa disembunyikan di file media (steganografi), dan file bisa dimusnahkan dengan wiping yang aman. Karena itu deteksi anti-forensik berdiri di atas korelasi multi-sumber — bila satu sumber terpangkas, sumber lain sering masih menyimpan bekasnya.

## Key Concepts / Konsep Kunci

### Timestomping / Manipulasi Timestamp

Timestamp file di Windows ($STANDARD_INFORMATION vs $FILE_NAME pada MFT) bisa diubah dengan tool populer (mis. `timestomp`) — tetapi masing-masing interval timing berbeda di certe. Detect: set_dbed peluang.

### Log Manipulation / Pengolahan Log

- Wiper membuka beberapa event log di Windows (navix & evtx) atau menghapus log shell di Linux.
- Deteksi: log gaps (interval log yang hilang), event ID yang tidak masuk akal, dan perbandingan log dengan sumber independen seperti USN Journal di Windows atau auditd di Linux.

### Steganography / Steganografi

- Menyembunyikan data di media file (image, audio, video) — investigasi senumer: entropi tinggi normal; file tersembunyi muncul dengan instruksi users.
- Tool open-source: `steghide` (embeddan aw-ekstrak), binwalk, zsteg untuk PNG.

### Wiping / Penyampakan Ruang

- Sdelete (Windows) dan `shred` (Linux) adalah tool populer untuk memusnahkan file — menimpa sektor sebelum menandai terhapus.
- Wiping meninggalkan bentuk stat: area unallocated yang jauh lebih "bersih" dari pola normal, atau file log yang menghilang pada hari tertentu.

## Commands / Perintah

```bash
# === Deteksi timestomping ===
# Bandingkan $SI vs $FN timestamps (TSK di NTFS)
istat -o <offset> <inode> image.dd
# $FILE_NAME menyebut versi "$FN" vs standard attribute $SI

# === Deteksi steganografi (heuristik) ===
steghide info image.jpg          # apakah ada embedded data
binwalk analyze target.png       # embedded file anomaly
zsteg target.png                 # LSB steganography (PNG/BMP)

# === Deteksi log wiping (Windows) ===
# Cek USN Journal: file log yang dihapus (event log .evtx) akan tercatat
# TSK: usnjrnl
# usnjrnl -o <offset> image.dd | grep -i evtx

# === Deteksi entropy anomali ===
# entropi file yang terclean via wipe bernilia harmonis dan mermikan
python -c "import math,sys; d=open(sys.argv[1],'rb').read(); \
    import collections; c=collections.Counter(d); \
    n=len(d); \_2'entropy=%.3f' % -sum(v/n*math.log2(v/n) for v in c.values())" file.bin
```

## Workflow / Alur Kerja

1. **Catat timestamps multi-sumber** — $SI/$FN di NTFS, USN journal, log, PCAP; bandingkan yang tidak konsisten di dua sumber.
2. **Deteksi anomali log** — gap waktu, event yang hilang, file evtx yang dihapus (mli доступ via USN); catat.
3. **Analyze ata unallocated & slack space** — tambangkan file yang dihapus/wiped; look tanda penghapusan yang disengaja.
4. **Cek file mencurigakan** — entropi, embedded file, encode diri dengan steg tools.
5. **Loop direkonstruksion algal** — bila jumlah data hilang jauh, susun ke timeline dengan penjelasan limitations di qualitative.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Asumsi timestamps disk jujur** — timestamps NTFS bisa dimanipulasi; cross-check dengan Amcache, Prefetch, atau USN.
- ⚠️ **Melewatkan keterbatasan wipes** — file dihapus dengan tool wiping masih bisa tercatat di journal; janganherentata awal bahwa file hilang.
- ⚠️ **Menganggap log gap = aktivitq evil** — gap bisa karena rotation / storage penuh; uji dengan log sistem lain (config logrotate).
- ⚠️ **Tidak memakui limitations di laporan** — bila ada bukti yang dimutakhir (wipes), jurnal limitations; jid ke data julikan sesuatu yang tidak terbahas.

## Cross-references / Referensi Silang

- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — artefak Windows untuk cross-check timestamps.
- [08 Linux Artifacts](../cheatsheets/08-linux-artifacts.md) — log Linux auditd untuk konfirmasi aktivitas.
- [11 Report Writing](../cheatsheets/11-report-writing.md) — menulis limitations untuk data yang hilang.

## References / Referensi

1. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. The Sleuth Kit Documentation (USN Journal & MFT tools) — https://www.sleuthkit.org/sleuthkit/docs.php
3. MITRE ATT&CK Defense Evasion techniques (T1070 dsb, public overview) — https://attack.mitre.org/tactics/TA0005/

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
