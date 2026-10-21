# NIST SP 800-86 Summary / Ringkasan NIST SP 800-86

> **TL;DR**: NIST SP 800-86 menghubungkan teknik forensik dengan siklus penanganan insiden keamanan — empat fase teknik (collection, examination, analysis, reporting) dipetakan ke tiga aktivitas IR (prepare & secure-media, acquire & examine & analyze & report, site-closure).

## Latar Belakang / Background

NIST SP 800-86, berjudul *Guide to Integrating Forensic Techniques into Incident Response*, diterbitkan NIST pada 2006 dan tetap menjadi rujukan paling terstandar untuk integrasi forensik ke incident response. Dokumen ini ditulis untuk organisasi yang ingin proses investigasinya konsisten dan dapat diperiksa, bukan hanya untuk lembaga penegak hukum. Seluruh panduan berbasis tiga aktivitas IR utama dan menempatkan forensik sebagai bagian yang tak terpisahkan dari penanganan insiden.

## Fase Teknis / Technical Phases

| Fase | Fokus | Contoh output |
|---|---|---|
| **Collection** | memindahkan data dari host/network ke media investigasi | bit-stream disk, memory image, log export |
| **Examination** | memeriksa dan memfilter data untuk menemukan yang relevan | indexed artifacts, carved files, keyword hits |
| **Analysis** | menjawab pertanyaan investigasi dari data hasil examination | timeline, kesimpulan, korelasi |
| **Reporting** | menuliskan hasil supaya bisa dibaca ulang pihak ketiga | laporan forensik |

Pemisahan examination dan analysis penting: examination bekerja di level data (membuat data terlihat), analysis bekerja di level makna (menafsirkan data). Investigator di fase examination tidak perlu menarik kesimpulan; itu tugas fase berikutnya.

## Kaitan dengan Siklus IR / IR Integration

NIST SP 800-86 menaruh empat fase itu ke dalam tiga aktivitas keamanan:

1. **Prepare and secure media** — persiapan tool, storage, form, dan policy sebelum insiden terjadi.
2. **Acquire → Examine → Analyze → Report** — rangkaian kerja saat insiden berlangsung.
3. **Site closure** — pengembalian lokasi/bukti setelah investigasi selesai, termasuk retensi dan disposal.

## Konsep yang Sering Dipakai / Key Concepts

- **Integrity via hash** — setiap akuisisi disertai hash (MD5/SHA-1 pada dokumen aslinya; hari ini SHA-256 biasa ditambahkan).
- **Reproducibility** — aktivitas harus bisa diulang dari dokumentasi yang tertulis.
- **Multiple data sources** — data bisa datang dari network, host (disk, memory, log), maupun perangkat kecil (mobile, peripheral); tiap sumber punya teknik dan tantangan berbeda.
- **Integrasi ke IR** — forensik bukan proses lepas; empat fase tekniknya diikat ke alur penanganan insiden organisasi.

## Mengapa Ini Penting / Why It Matters

Bagi SOC dan tim DFIR di Indonesia, NIST SP 800-86 memberi ukuran umum yang dapat dipakai lintas organisasi: investigasi dianggap dapat dipertanggungjawabkan bila fase collection-nya terdokumentasi (hash, chain of custody) dan fase report-nya dapat diulang oleh pihak lain. Dokumen ini juga menegaskan bahwa bobot kesimpulan investigasi berdiri di atas ke lengkungan dokumentasi setiap langkah, bukan di atas kecanggihan tool yang menjalankan analisis.

### Catatan

Seluruh isi halaman ini adalah ringkasan dengan bahasa sendiri dari standar publik; petunjuk selalu baca dokumen asli NIST untuk konteks dan ketentuan resmi.

## References / Referensi

1. NIST SP 800-86 (dokumen menyeluruh PDF) — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. NIST SP 800-61 Rev. 2 — Computer Security Incident Handling Guide — https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. NIST SP 800-86 table di CSRC — https://csrc.nist.gov/projects/computer-forensic-guidelines

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
