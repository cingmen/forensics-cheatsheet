# Glosarium Forensik Digital / Digital Forensics Glossary
> Daftar istilah yang sering muncul di cheatsheets repo ini. Definisi disarikan dari sumber publik: NIST SP 800-86 & 800-92, RFC 3227 / 5424 / 5905, dan Federal Rules of Evidence. Susun urut alfabetis; PR selalu terbuka untuk menambah istilah.

| Istilah | Definisi singkat |
|---------|------------------|
| **Admissibility (Keterterimaan bukti)** | Syarat hukum agar log/temuan bisa diterima di pengadilan; log komputer tidak otomatis admissible — harus memenuhi kriteria tertentu (mis. Rule 803 FRE) |
| **Alert data** | Bukti jaringan berupa peringatan dari sensor signature-based (Snort/Suricata/Zeek); perlu waspada false positive |
| **Business records exception** | Prinsip hukum yang memungkinkan rekaman rutin organisasi diterima sebagai bukti; log yang dibuat setelah insiden tidak memenuhinya |
| **Chain of custody** | Jejak perwalian bukti: siapa memegang, kapan, dengan hash berapa — dari akuisisi sampai persidangan |
| **Checksum** | Nilai numerik hasil perhitungan atas isi pesan/file, dipakai mendeteksi korupsi atau perubahan data saat transmisi |
| **Custodian** | Saksi berwenang yang bertanggung jawab atas rekaman; bersaksi tentang akurasi, integritas, dan sistem logging yang dipakai |
| **Data reduction** | Prasyarat korelasi: kompresi, hapus duplikat, filter, dan gabungkan event serupa sebelum masuk mesin korelasi |
| **Event aggregation (de-duplication)** | Langkah korelasi #1: gabungkan event berulang menjadi satu agar tidak duplikasi |
| **Event correlation** | Teknik menghubungkan sekumpulan event dalam interval waktu tertentu untuk memberi makna baru (mis. 10 failed login = serangan) |
| **Event filtering** | Langkah korelasi #3: buang event yang tidak relevan |
| **Event masking** | Langkah korelasi #2: sembunyikan event downstream dari sistem yang gagal, agar tidak mengaburkan akar masalah |
| **Flow record (NetFlow/IPFIX)** | Metadata ringkasan percakapan jaringan (IP/port src-dst, byte, waktu); jauh lebih ringan daripada PCAP |
| **Forensic readiness** | Kesiapan organisasi sebelum insiden: logging memadai, penyimpanan legal-sound, prosedur akuisisi yang terlatih |
| **Full content data** | Bukti berupa paket penuh hasil capture (PCAP); paling granular, paling mahal storage |
| **Hash (MD5/SHA-256)** | Sidik jari kriptografi file; wajib dihitung saat akuisisi log/PCAP untuk membuktikan tak berubah |
| **IoC (Indicator of Compromise)** | Artefak digital yang menunjukkan penyusupan: lonjakan outbound, URL berbahaya, anomali login, traffic di port tak wajar, dsb. |
| **Lateral movement** | Gerak penyerang antar host internal, sering via SMB/RPC/RDP; tampil sebagai pola one-to-many |
| **Missing log** | Log yang hilang; bila server terbukti online (canary), hilangnya mengindikasikan penghapusan disengaja |
| **NTP (Network Time Protocol)** | Protokol sinkronisasi jam (UDP 123, presisi milidetik); prasyarat korelasi event lintas mesin |
| **Normalization (log)** | Prasyarat korelasi: format ulang log dari berbagai sumber ke satu schema agar bisa dianalisis bersama |
| **PCAP** | File capture paket penuh; bisa dianalisis ulang dengan tshark/Wireshark |
| **Root cause analysis** | Langkah korelasi #4: pisahkan symptom events dari root cause events |
| **Rule 803 (FRE)** | Ketentuan Federal Rules of Evidence tentang rekaman kegiatan rutin sebagai bukti (dibuat saat/di dekat waktu kejadian, oleh orang yang punya pengetahuan, dalam rutinitas) |
| **Session data** | Bukti berupa ringkasan percakapan dua entitas jaringan (waktu, endpoint, volume) |
| **SIEM** | Security Information and Event Management — platform agregasi + korelasi log skala besar |
| **Statistical data** | Bukti berupa profil agregat trafik (timestamp, protokol, ukuran/rata-rata paket); basis baseline "wajar" |
| **Syslog** | Standar de-facto pengiriman pesan log ke server terpusat (umumnya UDP 514; cleartext; lintas platform) |
| **Syslogd / syslog server** | Daemon/penerima pesan syslog; bagian tier "log analysis & storage" |
| **Time synchronization** | Sinkronisasi jam semua mesin (NTP/W32Time) agar timestamp bisa dikorelasikan |
| **Tshark** | Versi CLI Wireshark untuk analisis PCAP: filter display (-Y), ekstraksi field (-T fields -e) |
| **Zeek (Bro)** | Sensor yang mengubah trafik jadi log terstruktur (conn/dns/http/ssl/files.log) |
| **Beaconing** | Koneksi berulang periodik ke satu host (interval serupa, payload kecil) — tanda khas C2 |
| **Jamming** | Serangan nirkabel yang membanjiri frekuensi sehingga AP tak bisa dipakai klien sah |
| **Rogue access point** | AP dipasang di WLAN tanpa izin administrator |

## Sumber
1. NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response
2. NIST SP 800-92 — Guide to Computer Security Log Management
3. RFC 3227 — Guidelines for Evidence Collection and Archiving
4. RFC 5424 — The Syslog Protocol
5. RFC 5905 — Network Time Protocol Version 4
6. Federal Rules of Evidence, Rule 803

---
**Last updated**: 2026-10-29 · **Maintained by**: @cingmen
