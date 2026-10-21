# Disk Forensics Cheatsheet / Cheatsheet Forensik Disk

> **TL;DR**: Panduan praktis forensik disk — dari struktur partisi (MBR vs GPT), filesystem NTFS/ext4, sampai recovery file via Sleuth Kit (mmls, fls, icat) dan alur analisis penuh di Autopsy.

## Overview / Gambaran Umum

Forensik disk adalah fondasi analisis DFIR paling klasik: dari satu disk image, investigator bisa membaca filesystem, menemukan file yang dihapus, membaca timestamps, dan menyusun kronologi aktivitas pengguna. Meski banyak insiden modern belok ke artefak Windows/Linux, disk image tetap sumber kebenaran bagi hampir semua artefak lain — hampir semua artefak tertulis di disk.

Alur standar forensik disk dimulai dari image yang sudah tervalidasi (lihat [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md)) lalu masuk ke empat langkah: baca tabel partisi, masuk ke filesystem, temukan artefak yang relevan, lakukan recovery bila perlu. Sleuth Kit memberikan fondasi CLI-nya; Autopsy memberi frontend bergui untuk pekerjaan harian.

Disk forensik juga membaca hal-hal yang tidak tampak pada pemakaian normal: deleted file dapat di-recover karena entri direktorinya masih menempel di metadata; slack space masih menyimpan fragmen file lama; timestamps filesystem bisa dimanipulasi (timestomping) — karena itu disk forensik sering perlu memverifikasi dengan sumber lain seperti $MFT, USN journal, dan Prefetch sebelum menarik kesimpulan.

## Key Concepts / Konsep Kunci

### MBR vs GPT / Skema Tabel Partisi

- **MBR (Master Boot Record)** — skema klasik, maksimal 2 TB dan 4 partisi utama, tabel partisi di sektor pertama.
- **GPT (GUID Partition Table)** — schema modern (pas disk besar), beberapa salinan partisi table (membangun redundan), named partitions (GUID), biasanya disediakan EFI boot.

Dua skema dibaca dengan `mmls image.img` untuk menampilkan partisi dan offsetnya. Perhatikan: offset TSK memakai satuan sektor, bukan byte — salah satu kesalahan paling umum pemula.

### NTFS & exFAT & FAT32 / ext4 & FAT32

- **NTFS** (Windows): Master File Table (MFT) menyimpan metadata lengkap termasuk timestamps beresolusi tinggi (100 ns). NTFS juga punya Alternate Data Streams (ADS) — stream tersembunyi yang kadang dipakai malware.
- **ext4 (Linux)**: inode menyimpan metadata; resolusi timestamps berbeda; entri deleted biasanya masih ada di inode table sampai sektor aslinya di-overwrite.
- **FAT/exFAT** (flashdisk, kartu memori, disk eksternal): struktur sederhana; timestamps FAT beresolusi 2 detik dan banyak informasi tidak tercatat — buktinya lebih tipis.

### Deleted Files & Slack Space / File Hapus & Ruang Sisa

- File yang dihapus berarti entri direktorinya di-unlink; data masih ada sampai sektornya di-overwrite.
- **Slack space** adalah ruang sisa pada sektor terakhir file — sering menyimpan fragmen file lama yang informatif.
- Mounting image read-only menjaga entri deleted tetap utuh; tools TSK membaca metadata asli tanpa mengubahnya.

## Commands / Perintah (Sleuth Kit / TSK)

```bash
# Lihat partisi & offset (sub bil. MBR dsb)
mmls image.dd

# Info filesystem di offset tertentu (offset dalam sektor)
fsstat -o 2048 image.dd

# Daftar file (rekursif, stream path, termasuk deleted)
fls -r -p -o 2048 image.dd

# Metadata inode (timestamps, ukuran)
istat -o 2048 <inode> image.dd

# Recover file by inode
icat -o 2048 <inode> image.dd > recovered.bin

# Bodyfile untuk timeline
fls -m / -o 2048 -r image.dd > bodyfile.txt
# Biasakan: bodyfile → mikron timeline (log2timeline mactime dsb)
```

## Workflow / Alur Kerja

1. **Verifikasi image** — cek hash; bekerja di working copy, bukan master.
2. **Baca partisi** — `mmls` untuk struktur partisi & offset.
3. **Analisis filesystem per partition** — `fsstat`, `fls -r -p` untuk struktur file; ekonomis dengan triage dulu (filename filters).
4. **Cari artefak** — deleted files (fls -d), timeline (bodyfile), keywords, program execution (Prefetch/Amcache), user artefak.
5. **Recovery file** — `icat` per inode, atau tool recovery GUI (Autopsy).
6. **Timeline & report** — susun kronologi ke aktivitas pengguna; tandai bukti dengan EV-ID untuk laporan.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Salah offset** — harus sector, bukan byte; perhatikan output `mmls` (kolom `sector` vs `size`).
- ⚠️ **Analisis pada master, bukan working copy** — master tetap terkunci; kerja selalu di salinan.
- ⚠️ **Mengabaikan timestamps TZ** — semua timestamps filesystem punya timezone yang bisa berbeda; konsistenkan UTC untuk timeline.
- ⚠️ **Lupa slack space & unallocated** — data belum di-overwrite bisa menyimpan file lama penting.
- ⚠️ **Tidak menyimpan hasil per fase** — recovery dan timeline disimpan def secuencial; supaya out artifacts bisa dilacak kembali ke EV-ID.

## Cross-references / Referensi Silang

- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — cara membuat image-nya.
- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — artefak Windows yang dibuang di NTFS.
- [08 Linux Artifacts](../cheatsheets/08-linux-artifacts.md) — artefak Linux di ext4.
- [`tools/disk/sleuthkit-cli.md`](../tools/disk/sleuthkit-cli.md) — perintah TSK lengkap.

## Menyusun Timeline / Building a Timeline

Timeline adalah produk paling sering diminta dari analisis disk. Dengan Sleuth Kit, langkah awalnya adalah membuat bodyfile dari image, lalu mengubahnya menjadi timeline yang bisa dibaca. Bodyfile berisi satu baris per artefak filesystem dengan kolom yang dipisahkan tanda pipa: nama file, inode, mode, UID/GID, ukuran, waktu akses, waktu modifikasi, waktu perubahan metadata, dan waktu pembuatan.

```bash
# 1. Buat bodyfile dari partisi (offset 2048 sektor)
fls -m / -o 2048 -r image.dd > bodyfile.txt

# 2. Ubah bodyfile menjadi timeline yang bisa dibaca manusia
mactime -b bodyfile.txt -d > timeline.csv

# 3. Filter jendela waktu insiden (contoh: 19-20 Oktober 2026 UTC)
mactime -b bodyfile.txt -d 2026-10-19..2026-10-20 > timeline-window.csv
```

Untuk kasus yang lebih besar, bodyfile bisa digabung dengan artefak lain: event log, PCAP, dan riwayat browser. Alat seperti Plaso (log2timeline) melakukan penggabungan ini secara otomatis, tetapi prinsipnya sama: semua sumber waktu dinormalisasi ke UTC, lalu diurutkan. Timeline yang baik selalu menyebutkan sumber setiap baris sehingga pembaca bisa melacak balik ke EV-ID.

Perhatikan bahwa timestamp filesystem bisa memiliki empat nilai berbeda: modified (mtime), accessed (atime), changed (ctime), dan born (btime, bila didukung). Masing-masing punya makna berbeda. mtime berubah saat isi file ditulis, atime saat file dibaca, ctime saat metadata berubah, dan btime saat file dibuat. Kesalahan umum adalah menyebut semua nilai sebagai "waktu file diubah" — padahal pembaca teknis akan mempertanyakan hal itu.

## Studi Kasus: USB dan Exfiltrasi / Case Study

Bayangkan sebuah kasus insider: seorang karyawan diduga menyalin dokumen ke USB lalu membawanya keluar. Disk image laptop sudah tersedia. Fokus analisis disk di sini bukan mencari malware, melainkan membuktikan perpindahan file.

Langkah pertama adalah memeriksa artefak USB di registry SYSTEM, khususnya `USBSTOR` dan `MountPoints2`. Artefak ini menunjukkan perangkat apa yang pernah terpasang dan kapan. Langkah kedua adalah mencocokkan dengan event log Windows yang mencatat pemasangan perangkat, sehingga waktu pemasangan bisa dipastikan.

Langkah ketiga adalah mencari file yang relevan di filesystem. Jika file sudah dihapus, `fls -d` dan `icat` bisa memulihkannya dari unallocated space. Hash file hasil recovery dibandingkan dengan hash dokumen asli di server untuk memastikan isinya sama. Langkah keempat adalah menyusun timeline: pemasangan USB, pembukaan file, penyalinan, dan pencabutan perangkat.

Yang membuat kasus ini kuat bukan satu artefak, melainkan konsistensi antar sumber. Registry menunjukkan USB terpasang pukul 16:02, event log mencatat hal yang sama, dan timeline filesystem menunjukkan file dokumen diakses pada 16:03 lalu disalin ke drive E: pada 16:05. Tiga sumber independen yang saling menguatkan jauh lebih kuat daripada satu artefak yang dramatis.

## Checklist Analisis Disk / Disk Analysis Checklist

- [ ] Hash image diverifikasi terhadap form chain of custody.
- [ ] Analisis dilakukan pada working copy, bukan master.
- [ ] `mmls` dijalankan dan offset partisi dicatat.
- [ ] `fsstat` per partisi dijalankan untuk mengenali jenis filesystem.
- [ ] `fls -r -p` menghasilkan daftar file lengkap termasuk deleted.
- [ ] Bodyfile dan timeline dibuat dan disimpan sebagai artefak kasus.
- [ ] File hasil recovery diberi hash dan dirujuk ke EV-ID.
- [ ] Temuan merujuk ke bagian laporan, bukan hanya ke file mentah.

## Pertanyaan Umum / FAQ

**Apakah file yang dihapus selalu bisa dipulihkan?** Tidak. File hanya bisa dipulihkan jika sektornya belum ditimpa. Pada disk yang aktif dipakai setelah penghapusan, peluang recovery turun dengan cepat. Karena itu image harus dibuat secepat mungkin setelah insiden diketahui.

**Mengapa `fls` tidak menampilkan file yang saya lihat di Explorer?** Beberapa file adalah artefak sistem dengan atribut khusus, atau berada di partisi lain yang belum dianalisis. Pastikan offset partisi benar dan jalankan `fls` per partisi, bukan pada image secara keseluruhan.

**Apa bedanya `fls` dan `ils`?** `fls` membaca entri direktori, sedangkan `ils` membaca inode table secara langsung. File yang entri direktorinya sudah hilang bisa masih muncul di `ils`. Keduanya saling melengkapi.

**Bagaimana menangani disk terenkripsi?** Jika enkripsi aktif dan kunci tidak tersedia, analisis disk tidak mungkin dilakukan. Fokuskan upaya pada memori host yang hidup (untuk mencari kunci) atau pada backup yang tidak terenkripsi. Dokumentasikan keterbatasan ini di laporan.

**Kapan sebaiknya memakai Autopsy dibanding CLI?** Autopsy lebih cepat untuk triage awal dan presentasi temuan, sedangkan CLI lebih presisi untuk parsing massal dan otomatisasi. Banyak tim memakai keduanya: Autopsy untuk gambaran umum, TSK untuk verifikasi.

## References / Referensi

1. The Sleuth Kit Documentation — https://www.sleuthkit.org/sleuthkit/docs.php
2. Autopsy Documentation — https://sleuthkit.org/autopsy/docs/
3. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
4. RFC 3227 — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
