# Chain of Custody Cheatsheet / Cheatsheet Chain of Custody

> **TL;DR**: Chain of custody adalah rantai pencatatan siapa, kapan, di mana, dan untuk tujuan apa sebuah bukti digital berpindah tangan — cheatsheet ini merangkum konsep inti, formulir, alur kerja, dan kesalahan yang membuat bukti gugur di proses hukum.

## Overview / Gambaran Umum

Bukti digital sangat mudah dirusak kredibilitasnya: satu salinan yang tidak terdaftar, satu pemeriksaan "hanya sebentar", satu periode tanpa penanggung jawab yang jelas — dan kepercayaan pada bukti itu runtuh. Chain of custody (CoC) adalah jawabannya: catatan kronologis setiap tindakan pada bukti, dari saat diambil sampai saat dilepas atau dimusnahkan. Ini bukan formalitas birokrasi; ini fondasi yang membuat semua analisis yang dibangun di atasnya dapat dipertanggungjawabkan.

Bayangkan analisis menemukan malware di laptop karyawan. Tanpa CoC, dia tidak bisa menerangkan (1) kapan dan dari mana laptop itu diambil, (2) siapa yang menyerahkannya kepada siapa, dan (3) mengapa tidak ada peluang bukti dimanipulasi selama berpindah tangan. Begitu kasus berakhir di depan auditor, komite disiplin, atau aparat penegak hukum, pertanyaan pertama yang muncul bukan "apakah temuan teknisnya benar?" melainkan "apakah buktinya sah?" — dan hanya CoC yang bisa menjawabnya.

Aturan praktis yang memandu cheatsheet ini: hal paling penting daripada seberapa canggih tool yang dipakai adalah seberapa rapi bukti dibukukan. Formulir siap pakai ada di `templates/chain-of-custody-form.md`, dan formulir penerimaan bukti di `templates/evidence-intake-form.md`.

CoC juga melindungi investigator. Ketika ada klaim bahwa bukti diubah-ubah, log yang lengkap — lengkap dengan hash yang tidak pernah berubah — adalah pembelaan paling kuat. Sebaliknya, investigator dengan catatan yang berlubang harus siap mengakui bahwa integritas bukti tidak dapat dibuktikan, dan seluruh temuan turun bobotnya.

## Key Concepts / Konsep Kunci

### Evidence Handler / Penanggung Jawab Bukti

Evidence handler adalah orang yang pada satu titik waktu bertanggung jawab penuh atas integritas bukti. Prinsip dasarnya: satu handler pada satu waktu (single-handler principle). Dua syarat yang harus terpenuhi: (a) handler memahami prosedur penanganan bukti; (b) setiap handover terdokumentasi lengkap. Volume kasus bisa tinggi, tetapi dokumentasi itu tidak bisa diisi ulang setelah kejadian — yang tidak dicatat saat itu akan tetap bolong selamanya.

### Evidence Locker / Lemari Penyimpanan Bukti

Evidence locker adalah lokasi penyimpanan fisik atau logis yang aksesnya dikendalikan. Aturan dasar: akses dibatasi (daftar nama terbatas, kunci khusus), ada logbook masuk-keluar, idealnya ada kamera, dan setiap item punya ID unik yang tertaut ke form CoC. Praktik yang biasa: master image disimpan di evidence locker, sedangkan salinan kerja (working copy) dipisahkan untuk dianalisis.

### Transfer Log / Log Transfer

Transfer log — bisa berupa file, spreadsheet, atau sistem manajemen kasus — mencatat setiap handover: dari siapa ke siapa, kapan, untuk tujuan apa, serta metode penyimpanan dan tanda tangan kedua pihak. Praktik yang lazim: modal serah-terima "hand-to-hand" dengan tanda tangan di kedua sisi, sehingga andaian "saya sudah serahkan kemarin" tidak menggantung tanpa bukti.

### Hash Verification / Verifikasi Hash

Hash (MD5/SHA-256) adalah sidik jari bukti digital. CoC tanpa hash baru terasa lemah ketika dipertanyakan di forum yang tegas: ganti sedikit, hash berubah total. Aturan idealnya sederhana:

1. Saat akuisisi: hitung hash, catat di form CoC.
2. Setiap salinan baru (working copy, berkas ekspor ke pihak ketiga): hitung hash salinan dan bandingkan dengan asal.
3. Sebelum analisis: verifikasi hash sekali lagi.
4. Sebelum penyajian di pengadilan atau audit: verifikasi terakhir.

Contoh:

```bash
# Hitung hash saat bukti masuk
sha256sum evidence.img | tee evidence.img.sha256
md5sum    evidence.img | tee evidence.img.md5

# Verifikasi setelah transfer atau sebelum analisis
sha256sum -c evidence.img.sha256
md5sum    -c evidence.img.md5
```

## Templates / Formulir

Formulir siap pakai ada di folder `templates/`:

| Formulir | Kapan dipakai |
|---|---|
| [`templates/chain-of-custody-form.md`](../templates/chain-of-custody-form.md) — form inti: case info, evidence info, hash verification, custody transfer log, final disposition | 1 bukti = 1 form |
| [`templates/evidence-intake-form.md`](../templates/evidence-intake-form.md) — penerimaan bukti dari pihak luar atau hasil triage SOC | Saat bukti masuk lab |
| [`templates/evidence-label-template.md`](../templates/evidence-label-template.md) — label fisik per bukti EV-ID | Tempel pada kantong/box bukti |

## Commands / Perintah

Command yang relevan sudah tercantum pada bagian Hash Verification. Prinsip utamanya: hash selalu mengiringi mutasi bukti — siapa-perintah-apa yang tertulis, hash yang dicantumkan.

## Workflow / Alur Kerja

1. **Intake** — tetapkan Evidence ID (EV-YYYY-NNN), foto kondisi fisik, tulis deskripsi (merek, serial number, status daya), catat tanggal-waktu penerimaan — di sinilah CoC dimulai. Pastikan tanda tangan pengirim dan penerima tercantum di form.
2. **Hash & penyimpanan awal** — hitung hash MD5/SHA-256 hasil akuisisi, catat di form CoC dan file hash terpisah; simpan master di evidence locker, catat lokasi locker di form.
3. **Working copy** — buat salinan kerja; master tetap terkunci di locker, bukan dipakai untuk analisis. Verifikasi hash salinan terhadap master, dan catat siapa menerima salinan kerja di CoC.
4. **Transfer** — bila bukti berpindah tangan (mis. ke analyst lain atau vendor): buat entri transfer pada form — from/to, tanggal-waktu, tujuan, lokasi penyimpanan, tanda tangan kedua pihak.
5. **Analysis** — seluruh analisis berjalan pada working copy yang tervalidasi hashnya; tindakan yang mengubah state salinan kerja (mount read-write, injection scripts) dicatat di CoC.
6. **Report & retention** — temuan di laporan merujuk EV-ID. Retensi mengikuti kebijakan organisasi.
7. **Disposal** — pengembalian, pemusnahan, atau penyimpanan permanen dicatat pada form: tanggal, metode, saksi, tanda tangan yang memutuskan.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Ada gap di custody log**: satu jeda "bukti ada di mana?" cukup untuk meruntuhkan kredibilitas bukti di forum formal.
- ⚠️ **Single-handler principle dilanggar**: buktyu dipinjam antar-analyst tanpa entri form — catat transfer meski durasinya 10 menit.
- ⚠️ **Hash tidak dihitung atau tidak dicatat**: hash bukan opsional; ini bukti integral.
- ⚠️ **Master dan working copy tersimpan di tempat sama atau dipakai bergantian**: master seharusnya tidak disentuh setelah akuisisi.
- ⚠️ **Bukti masuk tanpa intake form**: bukti dari vendor/pihak luar yang tiba tanpa catatan awal sulit ditelusuri asal-usulnya.
- ⚠️ **Disposisi tidak dicatat**: pemusnahan tanpa catatan witness/tanggal membuat chain menjadi gantung di ujungnya.

## Cross-references / Referensi Silang

- [00 Methodology](../cheatsheets/00-methodology.md) — posisi CoC di fase identification & preservation.
- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — akuisisi image dan hashnya.
- [11 Report Writing](../cheatsheets/11-report-writing.md) — menghubungkan bukti ke laporan final.

## Pertimbangan Hukum & Cloud / Legal & Cloud Considerations

Sebagian investigator beranggapan CoC hanya relevan bila kasus akan masuk pengadilan — anggapan yang sering terbukti keliru. Auditor internal, proses disiplin HR, dan penegak hukum sama-sama mengandalkan integritas dokumentasi. Kalau kasus kemudian memanjang ke forum legal, catatan yang lengkap sejak hari pertama jauh lebih kuat dibanding rekonstruksi yang disusun tiga bulan kemudian.

Untuk bukti yang tersimpan di cloud (log S3, audit log M365, dan setara), catat dalam CoC: nama vendor, identitas tenant (tenant ID), timestamp akses log, kelengkapan export (full atau partial), dan hash manifest yang diberikan vendor. Biasakan pula mencatat siapa yang mengunduh log, kapan, dan untuk tujuan apa — jejak akses ini yang akan diperiksa auditor bila kemantapan bukti dipertanyakan.

Untuk container dan disk virtual (hypervisor snapshot), dokumen aktif: VM ID (disk path), host hypervisor, base image, dan konfigurasi storage. Detail ini sering terlewat karena dokumentasi terfokus pada bukti fisik, padahal seluruh investigasi modern menyentuh infrastruktur virtual.

## Retensi & Pemusnahan / Retention & Disposal

Kebijakan retensi harus dipahami sebelum kasus dimulai: jenis bukti apa yang disimpan berapa lama, siapa yang berwenang menentukan disposal, dan kondisi apa yang membuat bukti tidak boleh dimusnahkan (mis. ada court order yang belum selesai). Ketika sebuah bukti memasuki fase disposal, dokumentasi wajib mencantumkan: tanggal, metode (pemusnahan fisik atau wipe yang telah diverifikasi), saksi, penandatangan, dan hash terakhir sebelum dimusnahkan.

Form CoC ditutup pada bagian Final Disposition, tetapi form kasus itu sendiri tetap diarsipkan setelah buktinya hilang. Ini bagian yang paling sering diabaikan namun paling dicari saat audit tahunan — serta paling murah untuk diselesaikan dengan benar sejak awal.

## Contoh Kasus / Worked Example

Berikut skenario mini agar prinsip di atas mudah dibayangkan. Sebuah laptop karyawan diduga menyimpan malware. IT mengarahkan laptop ke tim DFIR pukul 09.14 WIB. Tech menerima laptop, memotret kondisi fisik, menulis EV-2026-014 di label, mengisi intake form, dan menghitung hash dari hasil akuisisi laptop itu (image E01). Hash ditulis di form CoC dan disimpan versi teksnya di folder kasus.

Analyst A meminta working copy pukul 13.00. Tech menyalin image, memverifikasi hash salinan, memberikan copy, dan form CoC menerima entri transfer baru. Analyst bekerja pada salinan itu, menemukan malware, dan menulis temunian di laporan yang merujuk EV-2026-014. Setelah selesai, master dikembalikan ke evidence locker; working copy dihapus setelah keputusan retention, bukan sebelumnya.

Contoh ini menegaskan prinsip yang dibahas: setiap perpindahan tangan dicatat, hash dijaga untuk semua salinan, dan master tidak pernah dianalisis langsung. Buat scenario latihan sederhana di tim secara rutin supaya form tidak hanya "ada di repo" tetapi benar-benar terpakai.

## References / Referensi

1. ISO/IEC 27037:2012 — *Guidelines for identification, collection, acquisition and preservation of digital evidence* — https://www.iso.org/standard/44381.html
2. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227
3. NIST SP 800-86 — *Guide to Integrating Forensic Techniques into Incident Response*, bagian akuisisi & integritas — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
4. NIST SP 800-61 Rev. 2 — *Computer Security Incident Handling Guide* — https://csrc.nist.gov/pubs/sp/800/61/r2/final

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
