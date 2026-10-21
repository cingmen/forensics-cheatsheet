# Evidence Acquisition Cheatsheet / Cheatsheet Akuisisi Bukti

> **TL;DR**: Panduan praktis akuisisi bukti digital dengan dd, dcfldd, dan ddrescue — memakai write blocker, verifikasi hash MD5/SHA-256, memilih tipe akuisisi (logical vs physical, live vs dead box), serta dokumentasi sesuai chain of custody.

## Overview / Gambaran Umum

Akuisisi adalah momen paling sensitif dalam investigasi forensik: kesalahan kecil di tahap ini bisa menggugurkan seluruh analisis setelahnya, tidak peduli seberapa mahir analyst membaca artefak. Tujuan akuisisi sederhana — menghasilkan salinan yang persis sama dengan asalnya, tanpa mengubah asal sedikit pun — tetapi praktiknya penuh jebakan: auto-mount yang menulis metadata filesystem, salah membedakan disk sumber dan disk tujuan, serta buffer cache OS yang menulis ke device tanpa disadari.

Ada dua mode dasar akuisisi:

- **Dead box** — device tidak dihidupkan; disk dilepas dari perangkat mati dan di-image "dingin", biasanya lewat write blocker hardware. Lebih aman karena tidak ada proses OS yang menulis ke disk selama penyalinan.
- **Live box** — device masih hidup; memori dan artefak runtime hanya bisa diambil dalam keadaan ini. Relevan untuk banyak insiden modern, tetapi OS host pasti menulis ke disk selama proses — kondisi ini harus dicatat sebagai perubahan yang tidak terhindarkan.

Pemilihan logical vs physical juga harus dijelaskan. **Physical acquisition** (bit-stream copy) menyalin seluruh sektor, termasuk deleted file, slack space, dan partisi tersembunyi — gambar forensik yang utuh. **Logical acquisition** hanya mengambil file dan folder yang terlihat oleh filesystem — lebih cepat dan lebih kecil, tetapi menutup banyak pintu investigasi dan karenanya harus diberi alasan eksplisit dalam dokumentasi. Praktik yang lazim: bit-stream adalah default; logical adalah pengecualian yang didokumentasikan.

## Key Concepts / Konsep Kunci

### Write Blocker / Penahan Tulisan

Write blocker adalah hardware atau software yang memastikan device bukti hanya bisa dibaca dan tidak bisa ditulis. Hardware blocker (Tableau, WiebeTech, dan sejenisnya) lebih dipilih karena bekerja di luar OS — tidak bergantung pada driver host dan konfigurasi yang bisa salah. Software blocker, misalnya menandai device read-only di Linux (`blockdev --setro`), berguna saat live acquisition, tetapi risikonya lebih tinggi karena layanan lain bisa me-remount device dalam mode baca-tulis.

### Hash Verification / Verifikasi Integritas

Setiap disk image harus punya dua hash: MD5 dan SHA-256. Hash adalah pembuktian integritas: nilai yang tidak berarti bukti tidak pernah berubah. Hash dihitung saat akuisisi dan segera dicatat di dua tempat — file `image.md5`/`image.sha256` yang ikut dalam arsip, dan form chain of custody. Contoh:

```bash
# Hitung dua hash pada image yang baru dibuat
md5sum    evidence.img | tee evidence.img.md5
sha256sum evidence.img | tee evidence.img.sha256

# Verifikasi saat menerima salinan dari pihak lain
md5sum -c    evidence.img.md5
sha256sum -c evidence.img.sha256
```

### Bit-stream Copy / Salinan Bit-stream

Salinan bit-stream (raw copy) menyalin setiap sektor, termasuk sektor kosong, file yang sudah dihapus, dan slack space. File hasilnya (`evidence.img`, `evidence.dd`, atau format E01) adalah file biasa di disk penyimpanan. Format raw paling kompatibel dengan semua tool utama: Autopsy, FTK, Volatility, Plaso, hingga Sleuth Kit. Format E01 dipakai bila butuh metadata internal dan kompresi.

### Storage Evidence / Penyimpanan Image

Image bisa berukuran ratusan gigabyte hingga beberapa terabyte. Siapkan media penyimpanan yang kosong, terenkripsi, dan teruji — bukan disk produksi yang sisa. Catat capacity, filesystem, dan encryption status media penyimpanan itu di dokumen kasus; disk artifact yang kemudian muncul di image harus bisa dilacak ke media yang tepat.

## Commands / Perintah

### dd — Penggunaan Dasar

```bash
# PENTING: pastikan /dev/sdX adalah disk SUMBER, bukan disk TUJUAN!
# Buat raw image dengan toleransi error
dd if=/dev/sdX of=evidence.dd bs=4M conv=sync,noerror status=progress

# Konversi raw ke E01 (EnCase) bila butuh metadata internal
# ewfacquire evidence.dd
```

### dcfldd — dd dengan hashing on-the-fly

```bash
# dcfldd menghitung hash saat menyalin; berguna untuk disk besar
dcfldd if=/dev/sdX of=evidence.dd bs=4M conv=sync,noerror \
       hashwindow=512M hashlog=evidence.dd.md5 hash=md5
```

### ddrescue — Untuk disk bermasalah

```bash
# ddrescue menyimpan progress di logfile; re-run melanjutkan dari titik terakhir
ddrescue -f -r3 -n /dev/sdX evidence.img rescue.log   # pass pertama: copy biasa
ddrescue -f -r3 -d /dev/sdX evidence.img rescue.log   # pass kedua: direct access (bad sectors)
```

### Mount image read-only

```bash
# Pasang image sebagai loop device read-only
losetup --find --partscan --read-only evidence.img
mount -o ro /dev/loop0p1 /mnt/evidence
# Untuk image Windows (NTFS): mount -o ro,loop -t ntfs-3g evidence.img /mnt/evidence
```

## Workflow / Alur Kerja

1. **Triage & persiapan** — tetapkan mode akuisisi (live/dead, logical/physical), siapkan media penyimpanan kosong yang terenkripsi, catat waktu UTC, dan pastikan disk sumber teridentifikasi dengan benar (bukan disk tujuan).
2. **Isolasi & write blocker** — untuk dead box: pasang write blocker hardware sebelum disk menyentuh host. Untuk live box: capture memori dulu karena data paling volatile, baru lanjut ke disk.
3. **Acquire** — jalankan tool sesuai command di atas. Untuk disk besar pakai `dcfldd` (hash sekali jalan); untuk disk bermasalah pakai `ddrescue`. Baca log tool dan catat pesan error yang muncul.
4. **Hash & verify** — hitung MD5 dan SHA-256, simpan ke file `.md5`/`.sha256`, catat di chain of custody. Verifikasi ulang dengan `md5sum -c` / `sha256sum -c`; bila hash tidak cocok, ulangi akuisisi.
5. **Log & store** — catat di form CoC: siapa, kapan, tool dan versinya, waktu mulai/selesai, serta hasil hash. Simpan master di evidence locker.
6. **Working copy** — buat salinan kerja untuk dianalisis; master tetap terkunci dan tidak disentuh.

## Triage vs Full Acquisition / Triage vs Akuisisi Penuh

Akuisisi penuh disk server besar — 10+ TB, RAID, atau cluster — bisa memakan waktu berhari-hari. Bila waktu investigasi terbatas, lakukan triage collection untuk mengambil artefak paling informatif lebih dulu: MFT, Prefetch, Registry hives, event logs, browser artifacts, dan daftar file berkas yang berubah. Triage seperti ini didokumentasikan sebagai "reduced collection" disertai daftar artefak yang diambil — supaya tidak muncul dugaan bahwa data diambil sebagian tanpa alasan. Akuisisi penuh menyusul bila insiden mengembang.

Untuk lingkungan cloud dan virtualisasi, kenali bentuk image per environment: VMDK, VHD, cloud snapshot, atau disk dari hypervisor host. Catat waktu snapshot dan hubungkan dengan kondisi sistem — kejelasan ini mempermudah penyusunan timeline dan mengurangi perdebatan "versi image mana yang benar" bila ada lebih dari satu salinan.

## Live Acquisition / Akuisisi Live

Prinsip akuisisi live: ubah sistem korban seminimal mungkin. Jalankan tool dari media eksternal atau pakai remote agent yang menjalankan collection terbatas lalu berhenti. Simpan hasil ke disk tujuan yang disediakan, bukan ke disk host yang sedang diinvestigasi. Selama proses, pantau antivirus/EDR yang bisa menghapus artefak di tengah penyalinan — bila perlu, matikan service yang mengganggu dan catat tindakan tersebut di dokumen kasus.

Tool live yang umum dipakai: FTK Imager untuk memory dan file capture, triage script internal untuk daftar artefak tertentu, dan remote collection tool (KAPE atau setara) untuk skala banyak host sekaligus.

## Contoh Alur / Worked Example

Skenario yang sering terjadi: laptop Windows terdampak phishing dan analyst perlu mengambil disk image. Device masih hidup. Alur live ke dead yang lazim:

1. Catat waktu UTC dengan `date`; mulai isi form CoC.
2. Capture memori via FTK Imager ke external drive; simpan hash hasil capture.
3. Setelah memori terselamatkan, matikan host dan pasang disk ke write blocker.
4. Jalankan `dcfldd if=/dev/sdX ...` untuk membangun full image dengan blok 4M dan hash sekali jalan.
5. Simpan master di evidence locker; verifikasi hash; buat working copy untuk analyst.

Setiap langkah dicatat dengan detail: versi tool, timestamp, hash, dan penanggung jawab. Dengan begitu laporan investigasi memuat data yang dapat direproduksi investigator lain.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Salah arah `of=`**: menulis ke disk yang salah dapat menimpa data di disk target. Selalu cek `lsblk -o NAME,SIZE,MODEL` sebelum menjalankan command.
- ⚠️ **Tanpa write blocker**: OS host bisa menulis ke disk bukti lewat mount atau service latar. Gunakan hardware blocker atau set device read-only secara eksplisit.
- ⚠️ **Acquisition ke disk yang sama dengan sumbernya**: ruang disk yang tersisa kecil menghasilkan image yang tidak lengkap. Gunakan media penyimpanan terpisah.
- ⚠️ **Hash tidak dihitung**: tanpa hash, integritas image tidak dapat dibuktikan; seluruh temuan bisa dipersoalkan.
- ⚠️ **Image di-mount read-write**: satu huruf yang salah (`rw` alih-alih `ro`) cukup membuat filesystem menulis metadata ke image. Cek mount options sebelum menjalankan command.
- ⚠️ **Disk terenkripsi diabaikan**: bila full-disk encryption aktif dan host masih hidup, capture memori dulu untuk kemungkinan menemukan key; bila host sudah mati, isi disk mungkin tidak terbaca tanpa kredensial.

## Cross-references / Referensi Silang

- [00 Methodology](../cheatsheets/00-methodology.md) — posisi akuisisi dalam kerangka DFIR.
- [01 Chain of Custody](../cheatsheets/01-chain-of-custody.md) — dokumentasi hash dan handover.
- [03 Volatile Order](../cheatsheets/03-volatile-order.md) — urutan capture memori sebelum disk.
- [`tools/acquisition/dd-commands.sh`](../tools/acquisition/dd-commands.sh) — kumpulan oneliner siap pakai.

## Dokumentasi Akuisisi / Acquisition Documentation

Dokumentasi akuisisi adalah bagian yang paling sering menyusul dan paling sering dipertanyakan di akhir. Minimal setiap akuisisi harus dicatat ke dokumen kasus atau form CoC dengan data berikut: waktu mulai/selesai (UTC), tool dan versinya, disk sumber dan disk tujuan (vendor, seri, ukuran), metode akuisisi (bit-stream atau logical, live atau dead), dan hasil hash. Tanpa catatan ini, investigasi sulit dipertanggungjawabkan dan pembaca laporan akan meragukan detail yang tidak konsisten.

Form di [`templates/chain-of-custody-form.md`](../templates/chain-of-custody-form.md) sudah menyediakan kolom-kolom tersebut. Isi saat proses berjalan, bukan beberapa hari setelahnya — analyst yang menunda sering kehilangan detail kecil yang justru penting saat disputasi.

## Checklist Persiapan Akuisisi / Acquisition Readiness Checklist

- [ ] Disk sumber dan disk tujuan sudah dicek dengan `lsblk -o NAME,SIZE,MODEL`.
- [ ] Write blocker terpasang atau device sudah di-set read-only.
- [ ] Media penyimpanan target terenkripsi dan kosong.
- [ ] Waktu UTC dicatat saat proses mulai.
- [ ] Hash MD5 dan SHA-256 dihitung dan dicatat.
- [ ] Form CoC untuk akuisisi ini sudah dibuka.
- [ ] Log output tool tersimpan sebagai file pendamping.

## References / Referensi

1. NIST SP 800-86 §3 — *Guide to Integrating Forensic Techniques into Incident Response* — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. NIST CFTT — *Computer Forensic Tool Testing* — https://www.nist.gov/itl/ssd/software-quality-group/computer-forensics-tool-testing-program-cftt
3. GNU ddrescue Manual — https://www.gnu.org/software/ddrescue/manual/ddrescue_manual.html
4. dcfldd — project documentation — https://sourceforge.net/projects/dcfldd/
5. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
