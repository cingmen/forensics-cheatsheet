# Report Writing Cheatsheet / Cheatsheet Penulisan Laporan Forensik

> **TL;DR**: Laporan forensik adalah artefak investigasi yang paling banyak dibaca tetapi paling sering kurang dirawat kualitasnya — cheatsheet ini merangkum struktur laporan yang solid (methodology → findings → limitations → recommendations), gaya bahasa yang aman secara legal, dan checklist penyusunan.

## Overview / Gambaran Umum

Seluruh jam kerja investigasi akhirnya dibaca lewat satu dokumen: laporan. Stakeholder non-teknis membaca ringkasan eksekutif; auditor menilai metodologi; tim legal menimbang klaim; tim SOC lain memakai temuan untuk memperbaiki detection. Laporan yang buruk membuang nilai kerja investigasi: temuan yang secara teknis tepat dapat ditolak hanya karena ditulis spekulatif, dan laporan yang terlalu singkat memicu pertanyaan berulang dari pembaca yang berbeda.

Struktur laporan forensik yang lazim dan teruji: **document control → executive summary → scope → methodology → evidence examined → findings → analysis → conclusion → limitations → recommendations → appendices**. Kerangka ini sejalan dengan ISO/IEC 27042 untuk analisis dan interpretasi bukti digital. Kalau organisasi atau auditor meminta bentuk siap pakai, gunakan template di [`templates/forensic-report-template.md`](../templates/forensic-report-template.md) sebagai tulang punggung.

Praktik penting yang mudah terlewat: menulis laporan dimulai dari kerja teknik sehari-hari, bukan di akhir. Setiap kali menjalankan tool investigasi, catat command, versi tool, hash bukti, timestamp UTC, dan hasil pentingnya. Di sinilah bahan laporan dikumpulkan — menulis laporan di bagian akhir seharusnya sekadar menyusun catatan, bukan merekonstruksi dari ingatan.

## Key Concepts / Konsep Kunci

### Executive Summary / Ringkasan Eksekutif

Bagian pertama yang dibaca manajemen — biasanya 1–3 paragraf yang menjawab: insiden apa, kapan mulai dan berakhir, akun atau host apa yang terdampak, dampaknya, dan kesimpulan investigasi (mis. ransomware masuk via attachment phishing, 32 host terdampak, data keluar via upload ke storage pribadi selama tiga hari). Hindari jargon teknis seperti C2, MFT, atau nama plugin — gayanya ringkas, faktual, dan ditulis untuk pembaca bukan teknisi.

### Methodology Section / Bagian Metodologi

Jelaskan standar yang dipakai (mis. NIST SP 800-86, ISO/IEC 27037), tool beserta versinya (Volatility 3.1.0, Autopsy 4.21, KAPE 0.13.0), tipe akuisisi, zona waktu standar investigasi, dan bagaimana integritas dikelola. Bagian ini bukan tempat mengungkap temuan; bagian ini memungkinkan pembaca ahli menilai apakah prosesnya dapat direproduksi. Bila analisis dilakukan pada salinan kerja, tulis eksplisit: "all analysis was performed on verified working copies; the master image was never modified".

### Findings / Temuan

Temuan adalah unit utama laporan. Setiap temuan wajib punya ID, severity, description, dan rujukan bukti sehingga pembaca bisa menyusul sampai file atau bagian bukti aslinya. Format yang praktis:

```markdown
### Finding 1 — Lateral Movement via SMB (High)
*Description*: Akun svc-scanner dipakai untuk mengakses \\fileops\IPC$ pada host lain.
*Evidence*: EVTX Security Log 4624 (EV-2026-014), timestamp 2026-10-19T04:12 UTC.
```

Pastikan setiap temuan punya: timestamp (selalu UTC), evidence ID terkait, dan tingkat keyakinan (confirmed / probable / possible) — agar tidak ada kesimpulan yang dibingkai sebagai fakta padahal masih interpretasi.

### Limitations / Keterbatasan

Bagian limitations sering dilewati padahal berbobot tinggi. Tulis dengan jujur: retention log yang tidak cukup, bukti yang terenkripsi, timestamp yang tidak dapat dicross-check, atau host yang sudah di-rebuild sebelum sempat dianalisis — semua dijelaskan di sini. Tujuan limitations bukan menunduk; limitations menjaga laporan dari dipakai melebihi konteks investigasi oleh pihak yang membaca tanpa latar belakang teknis.

## Workflow / Alur Kerja

1. **Kumpul bahan** — kumpulkan catatan per-tool, chain of custody, timeline, dan bukti pendukung (screenshot dan file output). Pastikan setiap temuan punya EV-ID tertaut.
2. **Draft isi teknis** — tulis scope, methodology, evidence examined, dan findings lebih dulu; conclusion dan analysis menyusul begitu temuan stabil.
3. **Review teknik** — minta rekan engineer memeriksa command, tools, timestamps, dan hash — dicocokkan terhadap catatan investigasi.
4. **Review eksekutif** — tulis executive summary dan recommendations; hapus jargon, tulis ulang kalimat yang terlalu panjang.
5. **QA final** — cek setiap klaim punya bukti; setiap bukti punya hash; cek format dan daftar appendix; pastikan ada satu sumber kebenaran (single source of truth).
6. **Sign-off & distribution** — tulis nama (nama, jabatan, tanggal), reviewer; tentukan klasifikasi (Confidential/Restricted) dan daftar penerima.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Spekulasi tanpa bukti** — kesimpulan harus dibangun dari bukti; dugaan ditulis di Limitations, bukan di Findings.
- ⚠️ **Zona waktu tidak dicantumkan** — timestamp tanpa offset bisa membalik urutan kejadian; selalu tulis UTC.
- ⚠️ **Versi tools tidak dicantumkan** — hasil plugin versi lama dan baru bisa berbeda; reviewer perlu tahu persis versi yang dipakai.
- ⚠️ **Limitations dihilangkan** — laporan yang terlihat sempurna justru menimbulkan kecurigaan; limitations sama pentingnya dengan findings.
- ⚠️ **Hash verification tidak disebut** — setiap bukti yang dirujuk temuan harus disertai pernyataan hash dan verifikasinya.

## Gaya Bahasa & Legal-Safe Wording / Pemilihan Kata

Laporan yang baik ditulis dengan gaya yang dapat dipertanggungjawabkan. Beberapa prinsip yang membantu:

1. Gunakan kalimat aktif dan singkat — struktur kalimat yang kompleks lebih rentan disalahpahami.
2. Pilih kata kerja sesuai tingkat kepastian: "found", "observed", "identified" untuk fakta yang didukung bukti; "indicates", "suggests", "is consistent with" untuk interpretasi.
3. Hindari kata "definitely" atau "clearly" bila buktinya masih berupa inferensi.
4. Jangan mengaitkan serangan ke individu atau yurisdiksi tanpa bukti yang memenuhi standar pembuktian — sebut indikator teknisnya, bukan penilaian pribadi.
5. Gunakan EV-ID untuk merujuk bukti (EV-2026-014), bukan nama atau nomor pribadi, demi menjaga kerahasiaan data subjek.
6. Cantumkan asumsi bila investigasi berjalan pada kondisi tidak ideal — mis. hanya subset log atau bukti yang terenkripsi.

## Checklist Review Laporan / Report Review Checklist

Sebelum laporan diterbitkan, jalankan checklist ini:

- [ ] Executive summary terbaca oleh stakeholder non-teknis tanpa jargon berlebih
- [ ] Setiap finding punya severity, evidence ID, dan timestamp
- [ ] Methodology menyebut tool + versi, standar, dan zona waktu
- [ ] Limitations dijelaskan dengan jujur, bukan menggantung
- [ ] Tidak ada interpretasi yang diajukan sebagai fakta mutlak
- [ ] Semua timestamp dalam UTC dan konsisten antar bagian
- [ ] Hash verification disebut untuk semua bukti yang dirujuk
- [ ] Appendix mencantumkan raw output dan daftar tools
- [ ] Nomor halaman, revision history, dan version ID konsisten

## Distribusi & Klasifikasi / Distribution & Classification

Laporan selesai bukan berarti pekerjaan selesai: dokumen perlu didistribusikan ke pembaca yang tepat dengan klasifikasi yang tepat. Skema klasifikasi organisasi biasanya sederhana — Internal, Restricted, Confidential — dan setiap laporan menyebut klasifikasinya di halaman pertama. Daftar penerima yang tidak jelas mencerminkan pengelolaan dokumen yang buruk; pastikan setiap penerima punya kebutuhan nyata atas isinya.

Untuk kasus yang berpotensi berakhir di forum hukum, tetapkan klasifikasi lebih tinggi sejak draft pertama, dan pantau siapa yang membagikan dokumen. Revisi laporan selalu menaikkan nomor versi (v1.0 → v1.1) dengan changelog singkat di halaman revision history — sehingga tidak ada versi lama yang terkirim ke pihak yang salah.

## Distribusi Eksternal / External Audience

Bila laporan diserahkan ke pihak eksternal (vendor, regulator, atau penegak hukum), lakukan review legal terlebih dahulu, redact data PII, dan perpendek appendix menjadi versi ringkas. Berikan versi terakhir yang diberi tanda "external edition" agar tidak terjadi konflik versi dengan dokumen internal.

## Menyimpan & Meninjau Ulang Laporan / Archiving & Re-reviews

Laporan yang sudah ditandatangani perlu diarsipkan bersama dokumen pendukungnya: catatan investigasi, output tool, dan form chain of custody. Arsip kasus yang rapi memudahkan tiga kebutuhan: (1) referensi bila insiden serupa terjadi lagi, (2) audit kepatuhan yang meminta bukti dokumentasi, dan (3) pembelajaran tim yang membandingkan temuan lama dengan data baru.

Bila temuan baru muncul setelah laporan terbit — mis. IOC baru dari threat intel yang cocok dengan kasus lampau — dokumentasikan sebagai addendum, bukan revisi diam-diam. Addendum menyebut nomor versi laporannya sendiri dan menjaga kesinambungan dengan laporan asli, sehingga pembaca tahu bahwa kesimpulan utama tidak berubah tanpa catatan.

## Menanggapi Pertanyaan / Handling Follow-up Questions

Laporan yang sudah terbit bukan berarti pekerjaan selesai: biasanya pembaca mengajukan pertanyaan lanjutan. Beberapa cara meresponsnya dengan rapi:

1. **Jawab dengan merujuk bab dan EV-ID** — tidak perlu menulis ulang data; arahkan pembaca ke bagian yang relevan.
2. **Catat pertanyaan berulang** — jika pertanyaan yang sama muncul dari dua pihak, kemungkinan besar laporan perlu diperjelas pada bagian itu di revisi berikutnya.
3. **Jangan menjawab di luar bukti** — bila pertanyaan menyentuh area yang tidak tercakup investigasi, jawab dengan menambahkan pernyataan limitations atau pernyataan bahwa investigasi tersebut di luar lingkup kasus.
4. **Simpan komunikasi di satu kanal** — hindari perbincangan lewat chat pribadi; laporan seharusnya satu pusat dokumen yang diperbarui teratur.

## Contoh Kalimat Temuan / Sample Findings Language

Perbedaan antara temuan yang kuat dan yang lemah sering hanya soal kalimat. Berikut beberapa contoh yang bisa dipakai sebagai pola.

**Lemah:** "Penyerang menggunakan PowerShell untuk mencuri data."

**Lebih kuat:** "Pada 19 Oktober 2026 pukul 04:12 UTC, proses `powershell.exe` (PID 4812) dijalankan oleh `WINWORD.EXE` dengan argumen `-enc`. Analisis blob base64 menunjukkan unduhan dari `hxxp://example[.]com/a.ps1`. Koneksi keluar ke IP 203.0.113.10 tercatat pada `netscan` dan firewall log."

Kalimat kedua menyebut waktu, proses, induk proses, bukti, dan korelasi. Pembaca bisa memverifikasi setiap klaim. Kalimat pertama hanya menyimpulkan tanpa jejak.

Untuk bagian kesimpulan, hindari kata yang terlalu kuat bila bukti tidak lengkap. Gunakan frasa seperti "berdasarkan bukti yang tersedia", "konsisten dengan", dan "tidak dapat ditentukan dari data yang ada". Ini bukan kelemahan, melainkan tanda profesionalisme: investigator yang tahu batas buktinya lebih dipercaya.

## Cross-references / Referensi Silang

- [00 Methodology](../cheatsheets/00-methodology.md) — fase DFIR yang harus tercermin di bagian methodology.
- [01 Chain of Custody](../cheatsheets/01-chain-of-custody.md) — menghubungkan bukti ke laporan final.
- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — sumber temuan pada kasus Windows.
- [`templates/forensic-report-template.md`](../templates/forensic-report-template.md) — kerangka laporan siap pakai.

## References / Referensi

1. NIST SP 800-86 §5 — *Guide to Integrating Forensic Techniques into Incident Response* — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. ISO/IEC 27042:2015 — *Guidelines for the analysis and interpretation of digital evidence* — https://www.iso.org/standard/44405.html
3. ISO/IEC 27037:2012 — *Guidelines for identification, collection, acquisition and preservation of digital evidence* — https://www.iso.org/standard/44381.html
4. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
