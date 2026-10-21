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

## Studi Kasus: Deteksi Timestomping / Worked Example

Sebuah kasus melibatkan eksekusi file yang diduga dipalsukan waktunya. Investigator menerima image disk dan diminta memastikan apakah timestamp file kunci dapat dipercaya.

Langkah pertama adalah membandingkan dua set timestamp di NTFS. Setiap file punya atribut `$STANDARD_INFORMATION` ($SI) dan `$FILE_NAME` ($FN). Keduanya menyimpan waktu, dan tool timestomping biasanya hanya mengubah $SI. Jika nilai $SI jauh lebih lama daripada $FN, itu indikasi manipulasi.

Langkah kedua adalah memeriksa USN Journal. Setiap perubahan metadata dicatat di journal, termasuk operasi yang mengubah timestamp. Dengan `usnjrnl` dari Sleuth Kit, investigator dapat melihat kapan file tersebut terakhir diubah dan apakah ada operasi yang tidak wajar pada waktu tertentu.

Langkah ketiga adalah membandingkan dengan sumber lain: Prefetch, Amcache, dan event log. Jika Prefetch menunjukkan file dieksekusi pada tanggal yang tidak sesuai dengan timestamp $SI, ada ketidakcocokan yang perlu dijelaskan. Dalam contoh ini, Prefetch mencatat eksekusi pada 18 Oktober, sedangkan $SI menunjukkan 2019 — bukti kuat bahwa timestamp dimanipulasi.

Langkah keempat adalah mendokumentasikan temuan dengan hati-hati: sebutkan nilai kedua atribut, sumber pembanding, dan kesimpulan bahwa timestamp tidak dapat diandalkan. Jangan menyimpulkan siapa yang memanipulasi tanpa bukti tambahan; cukup nyatakan bahwa manipulasi terjadi dan kapan kemungkinan besar dilakukan.

## Deteksi Steganografi / Steganography Detection

Steganografi menyembunyikan data di dalam file lain, biasanya media. Pendekatan deteksinya bertingkat:

1. **Pemeriksaan visual dan metadata** — ukuran file yang tidak wajar dibanding resolusi, metadata editor yang tidak konsisten, atau artefak visual.
2. **Uji tool khusus** — `steghide info`, `zsteg`, dan `binwalk` dapat mendeteksi data tersemat pada format tertentu.
3. **Analisis entropi** — area dengan entropi sangat tinggi di dalam file media bisa menandakan data terenkripsi/terkompresi yang disematkan.
4. **Perbandingan dengan file asli** — bila file sumber tersedia, perbedaan bit-level menunjukkan modifikasi.

Tidak semua hasil positif adalah bukti niat jahat; beberapa format media memang menyimpan data tambahan. Karena itu verifikasi dengan ekstraksi dan analisis isi. Jika data berhasil diekstrak, perlakukan sebagai bukti baru: hash, catat metode ekstraksi, dan simpan di evidence locker.

## Checklist Anti-Forensik / Anti-Forensics Checklist

- [ ] Bandingkan $SI dan $FN pada file kunci.
- [ ] Periksa USN Journal untuk perubahan metadata.
- [ ] Cocokkan timestamp dengan Prefetch, Amcache, dan event log.
- [ ] Periksa gap pada event log dan file log yang hilang.
- [ ] Uji file media mencurigakan dengan tool steganalisis.
- [ ] Periksa entropi area mencurigakan.
- [ ] Dokumentasikan semua ketidakcocokan dan keterbatasan.
- [ ] Simpan hasil ekstraksi dengan hash dan EV-ID.

## Analisis Log Wiping / Log Wiping Analysis

Penghapusan log adalah teknik anti-forensik yang paling sering dipakai setelah kompromi. Di Windows, penyerang dapat menghapus event log dengan `wevtutil cl`, PowerShell `Clear-EventLog`, atau tool pihak ketiga. Di Linux, penghapusan bisa berupa `rm` pada file log, pemotongan file (`truncate`), atau penghentian layanan logging.

Tanda-tanda yang perlu dicari:

1. **Event ID 1102** di Windows menandakan log Security dibersihkan. Event ini sendiri bisa dihapus jika penyerang membersihkan log setelahnya, tetapi sering tertinggal di SIEM.
2. **Gap waktu** pada log — misalnya tidak ada entri antara 02:00 dan 05:00 padahal host aktif. Bandingkan dengan log lain seperti Sysmon atau firewall.
3. **File log berukuran nol** atau lebih kecil dari biasanya pada waktu tertentu.
4. **Service logging berhenti** — di Linux, periksa status rsyslog/journald; di Windows, periksa service EventLog.

Untuk host Windows, USN Journal bisa menunjukkan bahwa file `.evtx` dihapus, meskipun isinya sudah hilang. Di Linux, auditd (jika aktif) mencatat akses ke file log, sehingga penghapusan dapat terlihat meskipun log aplikasi hilang.

Kesimpulan yang aman: jangan menyatakan "tidak ada aktivitas" hanya karena log kosong. Nyatakan bahwa log tidak tersedia, lalu jelaskan sumber lain yang dipakai untuk menyimpulkan timeline.

## Pertanyaan Umum / FAQ

**Apakah anti-forensik selalu disengaja?** Tidak. Beberapa tool pembersih sistem menghapus log dan Prefetch secara otomatis tanpa niat jahat. Bedakan antara artefak yang hilang karena kebijakan IT dan yang hilang pada waktu mencurigakan.

**Bagaimana jika semua timestamp dimanipulasi?** Fokus pada sumber yang lebih sulit dimanipulasi: USN Journal, log jaringan, dan artefak eksternal seperti SIEM atau backup. Kesimpulan harus menyebut bahwa timestamp lokal tidak dapat diandalkan.

**Apakah wiping benar-benar menghapus data?** Pada disk magnetik, sisa data bisa ada di area yang tidak tertimpa; pada SSD, TRIM dan wear leveling membuat recovery lebih sulit. Jangan mengasumsikan data hilang total, tetapi jangan juga menjanjikan recovery.

**Apakah steganalisis selalu berhasil?** Tidak. Steganografi modern bisa sangat sulit dideteksi tanpa tool khusus dan file pembanding. Jika tidak ditemukan bukti, tulis bahwa pencarian dilakukan dan tidak menemukan indikasi, bukan bahwa tidak ada data tersembunyi.

## Keterbatasan Analisis Anti-Forensik / Analysis Limits

Tidak semua dugaan anti-forensik bisa dibuktikan. Investigator perlu membedakan tiga kondisi: (1) bukti manipulasi ditemukan dan didukung beberapa sumber, (2) ada anomali tetapi tidak cukup untuk menyimpulkan manipulasi, dan (3) tidak ada anomali yang ditemukan. Ketiganya punya cara penulisan berbeda di laporan.

Untuk kondisi pertama, sebutkan artefak yang bertentangan dan sumber pembandingnya. Untuk kondisi kedua, tulis anomali apa adanya dan jelaskan mengapa kesimpulan belum bisa diambil. Untuk kondisi ketiga, jangan menulis "tidak ada anti-forensik"; tulis bahwa pemeriksaan dilakukan dengan metode tertentu dan tidak menemukan indikasi, disertai batasan metode tersebut.

Keterbatasan teknis yang wajar disebut antara lain: log yang sudah terrotasi, perangkat yang memakai enkripsi penuh, dan tool yang belum mendukung format terbaru. Menyebutkan batasan bukan tanda kelemahan analisis; justru menunjukkan bahwa kesimpulan dibangun dengan hati-hati.

## References / Referensi

1. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. The Sleuth Kit Documentation (USN Journal & MFT tools) — https://www.sleuthkit.org/sleuthkit/docs.php
3. MITRE ATT&CK Defense Evasion techniques (T1070 dsb, public overview) — https://attack.mitre.org/tactics/TA0005/

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
