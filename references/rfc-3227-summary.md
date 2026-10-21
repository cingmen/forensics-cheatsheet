# RFC 3227 Summary / Ringkasan RFC 3227

> **TL;DR**: RFC 3227 (*Guidelines for Evidence Collection and Archiving*) memberi dua konsep inti — urutan pengumpulan data berdasarkan volatilitas (volatile order) dan prinsip pengarsipan bukti supaya tidak berubah — dipakai sebagai acuan collection di IR forensik.

## Latar Belakang / Background

RFC 3227 diterbitkan IETF (2002) sebagai panduan non-standar mengenai pengumpulan dan pengarsipan bukti selama insiden jaringan. Meskipun pendeknya, dokumen ini salah satu yang paling sering dirujuk karena memuat daftar urutan data berdasarkan volatilitas — seberapa cepat hilang ketika sistem dimatikan — yang praktis jadi acuan umum DFIR.

## Konsep Kunci 1: Volatile Order / Urutan Volatilitas

Dokumen ini menyarankan bahwa data paling volatile (paling mudah hilang) dikumpulkan lebih dulu. Urutannya kira-kira seperti ini:

1. Registers, cache — saat turn off daya
2. Routing table, ARP cache, process table, kernel statistics, memory
3. Temporary file systems
4. Disk / filesystem
5. Remote logging dan monitoring data yang tersimpan di sisi lain
6. Physical configuration, network topology
7. Archival media (backup)

Aturan praktisnya: semakin dekat data ke CPU dan memori, semakin cepat hilang — karena itu memori dan cache ditangkap lebih dulu daripada disk yang relatif stabil.

## Konsep Kunci 2: Evidence Archiving / Arsip Insiden

RFC 3227 menyarankan materi kasus tersimpan sejak awal:

- **Setiap insiden harus punya log** — kejadian dan tindakan penyelidikan tercatat berurutan.
- **Dua salinan independen** — buat copy utama dan backup pada situs maupun media yang berbeda.
- **Enkripsi & integritas** — arsip dienkripsi dan disertai hash sehingga perubahan dapat dibuktikan.
- **Kesiapan retensi** — durasi simpan mengikuti kebutuhan legal/kebijakan organisasi; jangan menghapus arsip sebelum timeline hukum aman.

## Prinsip Umum / Principles

RFC 3227 juga menegaskan hal-hal berikut:

1. **Order of volatility** — koleksikan data paling volatile lebih dulu.
2. **Accountability** — tindakan apa pun yang menyentuh bukti harus tercatat dan dapat diperiksa.
3. **Admissible evidence** — bukti yang dikumpulkan tanpa prosedur yang benar dapat ditolak pada forum formal.

## Mengapa Ini Penting / Why It Matters

Bila organisasi memakai RFC 3227 sebagai baseline pengumpulan bukti, urutan capture live acquisition tidak lagi ditentukan ad hoc per analyst — sudah ada acuan publik yang bisa dikutip di dokumen kasus. Ini memperkecil perdebatan saat investigasi ditinjau oleh pihak ketiga.

## References / Referensi

1. RFC 3227 — Guidelines for Evidence Collection and Archiving — https://www.rfc-editor.org/rfc/rfc3227
2. NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
3. RFC 793 — Transmission Control Protocol (TCP) — https://www.rfc-editor.org/rfc/rfc793

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
