# DFIR Methodology Cheatsheet / Cheatsheet Metodologi DFIR

> **TL;DR**: Cheatsheet ini merangkum kerangka metodologi DFIR berbasis standar publik — NIST SP 800-86, NIST SP 800-61, ISO/IEC 27037, dan RFC 3227 — supaya investigator punya alur kerja yang terstruktur, dapat dipertanggungjawabkan, dan bisa diulang dari fase identifikasi insiden sampai pelaporan.

## Overview / Gambaran Umum

Digital Forensics & Incident Response (DFIR) adalah dua disiplin yang saling terkait erat di dunia keamanan siber modern. Incident response berfokus pada bagaimana organisasi menangani insiden keamanan secara cepat dan terukur — mulai dari deteksi awal, penahanan (containment), sampai pemulihan layanan. Digital forensics berfokus pada bagaimana bukti digital dikumpulkan dan dianalisis secara sah, sehingga temuan investigasi bisa dipakai untuk audit internal, disiplin karyawan, proses hukum, atau setidaknya menyusun kesimpulan teknis yang tahan uji. Karena keduanya sering berjalan paralel pada kasus yang sama, praktisi modern menyebut gabungan keduanya sebagai DFIR.

Masalah yang paling sering muncul di lapangan adalah investigasi yang dilakukan tanpa metodologi. Analyst memburu indikator tanpa mendokumentasikan apa yang dikerjakan, mengubah sistem yang sedang diinvestigasi tanpa sadar, atau memerintahkan shutdown host yang masih menyimpan data memori — sebuah langkah yang bisa menghapus bukti paling berharga dalam hitungan detik. Metodologi yang baik tidak membuat investigator lambat; sebaliknya, metodologi memberikan urutan kerja yang efisien dengan jaminan bahwa bukti yang dikumpulkan tetap sah dan dapat diulang (reproducible) oleh pihak ketiga.

Sejumlah standar publik menjadi fondasi utama praktik DFIR. NIST SP 800-86, *Guide to Integrating Forensic Techniques into Incident Response*, menghubungkan empat fase teknis forensik — collection, examination, analysis, reporting — ke dalam siklus penanganan insiden. ISO/IEC 27037, *Guidelines for identification, collection, acquisition and preservation of digital evidence*, memperluas cakupan ke peran manusia dan integritas bukti di seluruh lingkungan infrastruktur. RFC 3227, *Guidelines for Evidence Collection and Archiving*, memberi panduan praktis mengenai urutan penyimpanan data yang paling mudah hilang (volatile order) dan arsip bukti. Ketiganya saling melengkapi: NIST menghubungkan teknik ke insiden, ISO menstandarkan peran dan integritas, RFC memberi detail teknis penangkapan dan penyimpanan.

Cheatsheet ini dipakai saat insiden sedang berjalan: analyst harus tahu urutan tindakan apa yang diutamakan, memanggil tools apa, mendokumentasikan apa yang terjadi, dan keputusan mana yang membawa konsekuensi legal. Tim SOC lokal di Indonesia — yang sering bekerja tanpa tim forensik khusus — rutin menghadapi insiden ransomware, phishing, insider threat, dan penyalahgunaan infrastruktur, sehingga alur metodologi yang terdokumentasi dengan baik membantu menjaga praktik tetap selaras dengan standar internasional.

Perlu dicatat juga bahwa metodologi adalah kerangka kerja, bukan penjara aturan. Di lapangan, keputusan bisnis — misalnya server produksi yang terlalu kritis sehingga tidak boleh diambil offline — sering memaksa kompromi teknis. Yang penting: kompromi itu harus dicatat secara eksplisit — kapan, atas izin siapa, dengan risiko apa. Investigator yang dokumentasinya lengkap akan jauh lebih mudah membelanya di depan komite atau pengadilan dibanding investigator yang hebat dengan tool tetapi tidak punya catatan.

## Key Concepts / Konsep Kunci

### Identification / Identifikasi

Fase identifikasi adalah tahap paling awal di mana organisasi menyadari ada kejadian tidak normal dan memutuskan apakah itu layak ditangani sebagai insiden. Sinyal bisa datang dari banyak sumber: alert di SIEM/EDR, laporan karyawan, anomali pada tagihan cloud, bahkan telepon dari pihak eksternal. False positive biasanya jauh lebih banyak daripada insiden asli, sehingga analyst perlu verifikasi awal — membandingkan log mentah dengan baseline aktivitas yang wajar — sebelum menetapkan severity dan melebarkan lingkup investigasi.

Contoh sederhana: alert "powerShell.exe melakukan koneksi keluar ke IP asing" berasal dari server produksi. Sebelum mendeklarasikan insiden, analyst membuka SIEM dan melihat bahwa PowerShell tersebut adalah script backup terjadwal milik tim platform, dengan IP tujuan yang sudah lama memang begitu. Alert bisa senyap. Sebaliknya, kalau IP tujuan belum pernah terlihat dan user-nya adalah service account yang tidak seharusnya melakukan koneksi keluar, level insiden dinaikkan dan investigasi diperluas.

### Preservation / Pengawetan Bukti

Pengawetan berarti menjaga keadaan sistem yang relevan agar tidak berubah lebih dari semestinya. Ada dua macam keadaan yang harus dirawat: (1) live systems yang masih beroperasi — harus dijaga agar data memori dan log aktif tidak hilang sebelum sempat dipindahkan; (2) evidence offline yang sudah berupa disk image — harus disimpan di environment terkendali (evidence locker, write blocker jauh dari device lab, airgap). ISO/IEC 27037 menekankan kondisi "as found" — keadaan saat pertama kali ditemukan — harus didokumentasikan (foto fisik, screenshot layar, catatan jumlah port yang terhubung) *sebelum* tindakan apa pun yang mengubah sistem.

### Collection / Pengumpulan

Pengumpulan adalah tindakan memindahkan data dari host/sistem/jaringan ke media penyimpanan investigasi, dengan jaminan integritas (hash MD5/SHA-256) dan catatan siapa-kapan-apa. Urutan penting ditentukan oleh volatility: memori terdahulu → cache & routing table → process & connection state → disk → backup/off-site. RFC 3227 memberi daftar urutan yang lazim digunakan. Alat yang umum untuk live collection: FTK Imager, dd/dcfldd, triage script khusus tim, dan sebagainya. Lihat cheatsheet [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) untuk command detailnya.

### Examination / Pemeriksaan

Examination adalah fase di mana data mentah dikonversi menjadi informasi yang bermakna: memfilter, mengurangi, dan menyederhanakan data besar. Contoh: mengekstrak hanya artefak yang relevan dengan insiden (MFT, Registry hives, event logs, browser history) dari full-disk image, mengindeks artefak tersebut, dan menurunkan volume data yang akan dianalisis. Prinsip utama pada tahap ini: jangan pernah mengoperasikan tool di media bukti asli — kerjakan selalu pada salinan.

### Analysis / Analisis

Analisis adalah fase di mana informasi diubah menjadi arti: analyst menjawab pertanyaan investigasi — dari mana penyerang masuk, teknik apa yang dipakai, sampai mana mereka biasa bergerak, dan apa yang diakses data. Alat konseptual yang berguna: pemetaan perilaku ke MITRE ATT&CK, korelasi artefak dari beberapa sumber (sysmon, firewall, memory dump, disk artefact), dan pendekatan hipotesis. Setiap kesimpulan harus didukung bukti; temuan yang masih berupa dugaan harus ditandai sebagai dugaan, bukan fakta. Lihat [11 Report Writing](../cheatsheets/11-report-writing.md) untuk penulisan output.

### Reporting / Pelaporan

Fase terakhir adalah menghasilkan output yang bisa dibaca stakeholder: ringkasan eksekutif, temuan dengan bukti, timeline kejadian, serta keterbatasan investigasi (limitations). Laporan forensik yang baik menjawab "apa yang terjadi" tanpa spekulasi, mencantumkan versi tools yang dipakai, dan merujuk appendix untuk detail. Sebab beberapa organisasi meminta format tertentu — mis. sejalan dengan ISO/IEC 27042 untuk analisis/interpretasi — sebaiknya cek kebutuhan hukum atau auditor sebelum menulis laporan pertama.

## Pemetaan Kerangka / Framework Mapping

Tabel berikut meringkas tiga kerangka yang paling sering dirujuk. Ketiganya tidak saling mempersulit — justru saling melengkapi dari sudut pandang yang berbeda.

| Aspek | NIST SP 800-86 | ISO/IEC 27037 | SANS PICERL |
|---|---|---|---|
| Fokus utama | Integrasi teknik forensik ke IR | Perlindungan bukti & peran personel | Siklus IR organisasi |
| Fase utama | Collection, Examination, Analysis, Reporting | Identification, Collection, Acquisition, Preservation, involved roles | Preparation, Identification, Containment, Eradication, Recovery, Lessons Learned |
| Gaya bahasa | Teknis, mengikuti folder-time activity | Formal standard internasional | Praktis, berbasis playbook |
| Cocok untuk | Organisasi yang mengikuti proses IR | Kasus yang berpotensi berakhir di hukum | SOC yang memakai playbook |
| Sumber publik | [SP 800-86 PDF](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf) | [Halaman ISO](https://www.iso.org/standard/44381.html) | [NIST SP 800-61](https://csrc.nist.gov/pubs/sp/800/61/r2/final) |

Catatan: kerangka PICERL populer dari materi internal SANS, namun inti konsepnya dapat dimaknai bebas menjala menggunakan NIST SP 800-61 yang tersedia gratis.

## Commands / Perintah

Cheatsheet ini lebih konseptual, tetapi ada beberapa command yang relevan untuk operasi harian metodologi mengikuti alur di atas:

```bash
# Coba papan status sistem saat pertama ditemukan (dokumentasi "as found")
date -u >> evidence.log; ps -ef >> evidence.log; netstat -rn >> evidence.log

# Di Windows host: simpan volatile state sebelum host diisolasi jaringan
wevtutil qe Security /f:text /c:50 >> "%EVID_DIR%\ev-security.txt"
tasklist /v        >> "%EVID_DIR%\tasklist.txt"
reg save HKLM\SYSTEM "%EVID_DIR%\SYSTEM.hiv"
```

```bash
# Di Linux host: ambil state volatile sebelum memutus jaringan
ss -tulnp > "$EVID/ss-state.txt"                 # listener & koneksi aktif
conntrack -L > "$EVID/conntrack.txt" 2>/dev/null # tabel conntrack (kernel)
auditctl -l > "$EVID/auditctl-rules.txt" 2>/dev/null
date -u                                          # UTC sebagai acuan investigasi
```

## Workflow / Alur Kerja

1. **Prepare** — siapkan toolkit, form chain of custody, media evidence kosong yang sudah ter-encrypt, dan kontak eskalasi. Waktu terbaik untuk latihan adalah sebelum insiden: jalankan tabletop sederhana setiap kuartal.
2. **Identify** — validasi alert, buka ticket insiden, tetapkan incident commander, ukur severity dan lingkup. Hindari tindakan ad hoc tanpa bukti kecuali konteks darurat (mis. exfiltrasi sedang berlangsung).
3. **Contain** — pisahkan host terdampak dari jaringan (network isolation, bukan shutdown) supaya memori tetap hidup. Simpan data volatile: capture full memory dump `sebelum` memutus koneksi, catat waktu UTC (dan offset zona asal).
4. **Acquire** — kumpulkan evidence sesuai volatile order: memori → cache/routing → process & connection state → disk (bit-for-bit copy dengan write blocker / dd / dcfldd / ddrescue). Setiap koleksi didokumentasikan di form chain of custody.
5. **Examine** — kerjakan di salinan bukti. Filter artefak, lakukan indexing, dan bangun timeline terpadu (super-timeline). Paralel: log analysis, memory analysis, network capture, disk artifacts.
6. **Analyze** — jawab pertanyaan investigasi berdasar bukti: entry point, lateral movement, data yang diakses/exfiltrated, persistence mechanisms. Bandingkan dengan threat intel dan pemetaan ATT&CK.
7. **Report** — tulis laporan sesuai template `templates/forensic-report-template.md`: executive summary, metodologi & tools, findings, analysis, conclusion, limitations, rekomendasi.
8. **Retain & lessons learned** — simpan evidence sesuai kebijakan retention, jalankan post-incident review, perbarui playbook dan detection rules.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Melakukan shutdown pada host terdampak**: shutdown menghapus isi memori (proses, koneksi jaringan, injected code). Gunakan network isolation, bukan pematikan daya.
- ⚠️ **Tidak menyamakan zona waktu investigasi**: log bisa memakai UTC maupun local time; ketidaksesuaian ini bisa memicu salah urutan kejadian. Selalu kerjakan dalam UTC dan catat offset dari sumber log.
- ⚠️ **Dokumentasi kurang**: sepuluh menit tanpa catatan sudah cukup untuk merapuhkan kepercayaan pada chain of custody. Catat saat itu, ringkas nanti.
- ⚠️ **Dikerjakan langsung pada disk asli**: semua analisis harus di salinan; disk asli tetap dalam evidence locker.
- ⚠️ **Mengambil image tanpa write-blocker**: OS host bisa memodifikasi device saat attached; tanpa write blocker, integritas bukti bisa rusak.
- ⚠️ **Menunda dokumentasi sampai investigasi "selesai"**: detail tak dapat ditebak setelah 24 jam.

## Cross-references / Referensi Silang

- [01 Chain of Custody](../cheatsheets/01-chain-of-custody.md) — formulir dan alur pembukuan custody mulai dari fase identification.
- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — command dd / dcfldd / ddrescue dan alur hashing.
- [03 Volatile Order](../cheatsheets/03-volatile-order.md) — urutan menangkap data volatile.
- [11 Report Writing](../cheatsheets/11-report-writing.md) — menuntask hasil analisis ke laporan.

## References / Referensi

1. NIST SP 800-86: *Guide to Integrating Forensic Techniques into Incident Response* — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
2. NIST SP 800-61 Rev. 2: *Computer Security Incident Handling Guide* — https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. ISO/IEC 27037:2012 — *Guidelines for identification, collection, acquisition and preservation of digital evidence* (public standard page) — https://www.iso.org/standard/44381.html
4. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227
5. MITRE ATT&CK Framework — https://attack.mitre.org/

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
