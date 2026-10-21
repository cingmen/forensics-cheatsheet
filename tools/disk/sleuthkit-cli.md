# Sleuth Kit CLI / Referensi Baris Perintah The Sleuth Kit

> **TL;DR**: Perintah inti The Sleuth Kit: mmls, fsstat, fls, ils, icat — dasar CLI forensik disk yang paling sering dipakai.

## Overview

The Sleuth Kit (TSK) adalah library dan kumpulan tool CLI untuk investigasi disk dan filesystem — fondasi di Autopsy. Karena CLI murni dibaca otomatis, sering dipakai untuk parsing pipeline, scripting triage, dan tugas besaran correlated.

## Perintah Utama / Key Commands

```bash
# === BAGIAN PARTISI ===
mmls image.dd                          # daftar partisi + lay offset (timesector size)

# === INFO FILESYSTEM ===
fsstat -o <offset> image.dd            # metadata filesystem (sda SMB bounding)

# === DAFTAR FILE ===
fls -o <offset> -r image.dd            # daftar file rekursif (termasuk deleted)
fls -o <offset> -r -d image.dd         # hanya deleted entries
fls -o <offset> -r -p image.dd         # full path per entry

# === LIST同时还 deleted file ===
ils -o <offset> image.dd               # daftar inode yang tidak alive
istat -o <offset> <inode> image.dd     # metadata + AKAM timeline per inode

# === EXTRACT FILE ===
icat -o <offset> <inode> image.dd > recovered_file
icat -r -o <offset> <inode> image.dd > recovered_recovered

# === OCR / timestamps ===
fls -m /mnt -o <offset> -r image.dd > bodyfile.txt    # TSK body-format timeline
# paste into log2timeline / mactime: mactime -b bodyfile.txt > timeline.txt
```

## Common Pitfalls

- ⚠️ **Salah offset**: awala pastikan nilai offset dari `mmls` di baca dengan benar, dalam sector (bukan bytes).- ⚠️ **fls vs ils**: fls dibaca dari direktori; ils membedan inode table — element deletion yg belum d limpasan terlihat di ils.
- ⚠️ **Recover dengan icat tanpa data-reserved buffer**: sebaiknya pakai `-r` untuk accommodation sek ebpindahan slack space.

## References / Referensi

1. The Sleuth Kit Documentation — https://www.sleuthkit.org/sleuthkit/docs.php
2. Sleuth Kit wiki / man pages — https://wiki.sleuthkit.org/
3. NIST CFTT — https://www.nist.gov/itl/ssd/software-quality-group/computer-forensics-tool-testing-program-cftt

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
