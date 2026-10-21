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

## References / Referensi

1. The Sleuth Kit Documentation — https://www.sleuthkit.org/sleuthkit/docs.php
2. Autopsy Documentation — https://sleuthkit.org/autopsy/docs/
3. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
4. RFC 3227 — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
