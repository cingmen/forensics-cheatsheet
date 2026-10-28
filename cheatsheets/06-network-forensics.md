# Network Forensics Cheatsheet / Cheatsheet Forensik Jaringan
> **TL;DR**: Forensik jaringan = analisis PCAP, flow, dan log (firewall/IDS/syslog) untuk menemukan sumber insiden: jalur masuk, teknik penyerang, dan bukti yang tersisa. Kenali empat jenis bukti jaringan (full content, session, alert, statistik), jaga log tetap kredibel secara hukum (NTP sinkron, hash saat akuisisi, akses terkontrol, server log terpusat), lalu korelasikan event lintas sumber sampai root cause.

## Gambaran Umum
Forensik jaringan adalah proses menangkap, merekam, dan menganalisis event jaringan untuk menjawab pertanyaan yang tidak bisa dijawab host saja: dengan siapa server berkomunikasi, pada jam berapa, mengirim data berukuran berapa, dan apakah polanya wajar. Tujuannya dua arah: menentukan penyebab insiden agar pengamanan bisa diperbaiki, dan mengumpulkan bukti terhadap pelaku untuk proses hukum.

Sumber datanya beragam: full PCAP (tshark/Wireshark), flow record (NetFlow/IPFIX), IDS alerts (Snort/Suricata/Zeek), log firewall, log DNS, dan log syslog terpusat. Pendekatan praktisnya berlapis: mulai dari potret umum (statistik per protokol/percakapan), turun ke filter spesifik (HTTP POST, DNS query, TLS handshake), lalu deteksi anomaly — beaconing, scanning, eksfiltrasi data, lateral movement via SMB/RPC.

Tantangannya nyata: capture trafik itu sederhana di teori tapi kompleks di praktik karena volume data dan kompleksitas protokol Internet. Merekam semua trafik jarang mungkin; rekaman perlu di-backup agar media tidak penuh; analisis adalah bagian paling kritis dan memakan waktu. Alat otomatis membantu, tetapi tidak ada metode yang bebas false positive — penilaian manusia tetap kunci. Trafik modern sebagian besar terenkripsi (TLS); meski isi tidak terbaca, metadata (SNI, ukuran paket, interval, tujuan) tetap sangat informatif.

## Konsep Kunci
### Postmortem vs Analisis Real-Time
| Aspek | Postmortem | Real-Time |
|-------|-----------|-----------|
| Objek | Insiden yang **sudah terjadi** | Serangan yang **sedang berlangsung** |
| Pola kerja | Log diperiksa berulang kali, teliti, exhaustif | Hasil keluar bersamaan dengan serangan; log mungkin hanya sempat dilihat sekali |
| Keunggulan | Bisa memverifikasi urutan event secara menyeluruh, dasar laporan final | Respons langsung, mitigasi sebelum kerusakan melebar |
| Risiko | Temuan datang setelah fakta | Tekanan waktu; keputusan dengan informasi parsial |

### Empat Jenis Bukti Berbasis Jaringan
| Jenis | Isi | Alat umum | Catatan |
|-------|-----|-----------|---------|
| **Full content data** | Paket penuh yang di-capture (PCAP) | tcpdump, Wireshark, tshark | Paling granular; mahal storage/CPU; bisa diputar ulang untuk analisis subset apa pun |
| **Session data** | Ringkasan percakapan antar dua entitas: IP/port src-dst, waktu mulai, volume | NetFlow, IPFIX, Argus | Ringan untuk skala besar; tidak ada isi payload |
| **Alert data** | Peringatan dari sensor yang memeriksa trafik | Snort, Suricata, Zeek | Bergantung signature; waspadai **false positive** |
| **Statistical data** | Profil/ringkasan agregat: timestamp, protokol, ukuran paket rata-rata, packet rate | Zeek stats, `tshark -z` | Berguna untuk baseline "wajar" vs anomali |

### Peta Bukti per Lapisan TCP/IP
| Lapisan TCP/IP | Protokol utama | Log dari mana |
|----------------|----------------|---------------|
| Application | HTTP(S), DNS, SMTP, FTP/TFTP, NFS, SNMP, Telnet | Server/web/app, antivirus, database, proxy, email gateway |
| Transport | TCP, UDP | Firewall, IDS/IPS |
| Internet | IP, ICMP, ARP, IGMP | Firewall, IDS/IPS, VPN |
| Network Access | Ethernet, Fast/Gigabit Ethernet, SLIP, PPP, FDDI, ATM, Frame Relay, SMDS | Router, switch |

Investigator perlu paham pemetaan OSI↔TCP/IP (Application+Presentation+Session→Application; Data Link+Physical→Network Access) supaya tahu log mana yang relevan untuk setiap jenis event.

### PCAP vs Flow / Capture Penuh vs Flow
- **PCAP** — capture paket penuh; bisa dibaca ulang isinya, tapi mahal storage dan CPU.
- **Flow record (NetFlow/IPFIX)** — hanya metadata percakapan; jauh lebih ringan; lazim di topologi besar.
- Investigasi memadukan keduanya: flow untuk skala besar, PCAP untuk deep-dive host tertentu.

### Beaconing / Pola Koneksi Berulang
- C2 beacon biasanya tampil sebagai koneksi berulang ke satu host pada interval serupa (30–300 detik).
- Jitter (variasi interval kecil) tidak menghapus pola; agregasi per 1–5 menit menggarisbawahi beacon.
- Indikator umum: SYN berulang ke satu IP, payload kecil dan seragam, kadang di luar jam kerja.

### Data Exfiltration & Lateral Movement / Keluarnya Data & Gerak Samping
- Eksfiltrasi klasik: upload besar ke host baru (FTP/S3, HTTP POST besar), sering di luar jam kerja.
- Lateral movement sering pakai SMB (PSEXec, admin share), RPC, atau RDP — tampil sebagai koneksi SMB2 ke banyak host internal dari satu host terinfeksi.
- Deteksi berbasis flow: pola "one-to-many" SMB dari satu sumber adalah tanda lateral movement yang jelas.

### IoC pada Level Jaringan
| IoC | Artinya | Log sumber umum |
|-----|---------|-----------------|
| Traffic keluar tak lazim | Lonjakan outbound bisa jadi tanda eksfiltrasi/serangan berjalan | NetFlow, firewall, proxy |
| URL berbahaya | URL hasil phishing/spam adalah kandidat IoC | Proxy, DNS, email gateway |
| User-agent string aneh | UA mencantumkan OS/browser perangkat; UA tidak wajar = tool otomatis | Web server, proxy |
| Anomali login | Lonjakan failed login pada satu akun = indikasi brute force | Auth/SSH/VPN log, SIEM |
| Request berulang ke file yang sama | Banyak permintaan ke satu file = jejak upaya infiltrasi | Web server, IDS |
| Traffic di port tak wajar | Program "berpura-pura" sah lewat port tidak standar | Firewall, flow, Zeek |

### Taksonomi Serangan Jaringan Kabel
| Serangan | Inti | Jejak yang dicari |
|----------|------|-------------------|
| Eavesdropping | Menyadap koneksi tak terenkripsi untuk mencuri data | Mirror/rogue port, trafik plaintext |
| Data modification | Mengubah/menghapus data setelah akses didapat | Integrity hash, log perubahan |
| IP spoofing | Mengirim paket dengan IP sumber host terpercaya | ARP/IP anomaly, paket dengan TTL tak wajar |
| DoS/DDoS | Membanjiri target sampai sumber daya habis | Lonjakan many-to-one, SYN flood |
| Man-in-the-Middle | Menyisip antara dua pihak yang mengira bicara langsung | ARP spoofing, sertifikat mismatch |
| Packet sniffing | Menangkap trafik (mis. tools seperti Cain & Abel) untuk user/password | Promiscuous mode, koneksi plaintext |
| Enumeration | Memetakan topologi, host hidup, arsitektur trafik (TCP/UDP/IPX), celah host | Scan port/ICMP massal, kueri SNMP/NetBIOS |
| Session hijacking | Menyalahgunakan mekanisme token sesi untuk koneksi tak sah | Token reuse, geolocation aneh |
| Buffer overflow | Melampaui kapasitas buffer hingga menimpa data sah | Crash, alert IPS signature |
| Email infection | Spam/flood email untuk membanjiri jaringan (efek DoS) | Log SMTP, volume lampiran |
| Malware attack | Membujuk pengguna memasang kode jahat | C2 beacon, hash file, IDS |
| Password-based attack | Ribuan percobaan login untuk menebak kredensial | Failed login berulang |
| Router attack | Mengkompromikan router untuk akses jaringan | Log admin router, config change |

### Taksonomi Serangan Nirkabel
| Serangan | Inti | Petunjuk deteksi |
|----------|------|------------------|
| Rogue access point | AP dipasang di WLAN tanpa izin admin | APU baru di RF survey, MAC tak terdaftar |
| Client misassociation | Klien tertarik ke AP di luar jaringan (signal kuat, tanpa kunci) → jadi pintu masuk | Log asosiasi klien, arah asosiasi |
| Misconfigured AP | AP salah konfigurasi → buka celah bagi penyerang | Audit konfigurasi, scan wajar |
| Unauthorized association | AP software (radio di laptop) diaktifkan di sistem korban | Koneksi ad-hoc tak dikenal |
| Ad-hoc connection | Perangkat USB adapter menyambung langsung ke station tidak aman | Log adapter nirkabel |
| Honeypot AP attack | AP penyerang dengan SSID sama & signal lebih kuat; klien bergantian AP otomatis | Duplikasi SSID, kegagalan handshake |
| AP MAC spoofing | MAC dipalsukan agar terlihat sebagai AP sah (tools mac-changer/SMAC) | Ketidakcocokan OUI/vendor, duplikasi MAC |
| Jamming | Sinyal dibanjiri (jammer) sehingga AP tak bisa dipakai | Drop S/N ratio, kegagalan asosiasi massal |

## Kesiapan Forensik Jaringan (Forensic Readiness)
Kemampuan tim untuk cepat mengidentifikasi, mengakuisisi, dan memeriksa bukti jaringan sangat bergantung pada persiapan organisasi **sebelum** insiden. Kesiapan ini meliputi: event logging yang memadai, pengumpulan data yang bisa jadi artefak kunci, penyimpanan log secara legal-sound, serta penjagaan autentisitas dan integritas log. Tanpa persiapan, banyak bukti jaringan (volatile, tidak tersimpan, ter-overwrite) hilang sebelum sempat dianalisis.

### Kriteria Legal Log sebagai Bukti
- Regulasi mewajibkan pengelolaan log yang forensically sound (konteks AS: FISMA 2002, HIPAA, PCI DSS, SOX 2002, GLBA; di Indonesia bandingkan kebijakan BSSN dan UU PDP). Di luar konteks ini, prinsipnya sama: log rutin, aman, dan terdokumentasi.
- Enam poin yang membuat log layak diterima sebagai bukti:
  1. Log dibuat **konsisten dengan event** yang diselidiki — bukan kompilasi acak.
  2. Log disimpan di **lokasi aman** untuk mencegah tampering.
  3. Log dipelihara sebagai **rutinitas operasional** (business practice), bukan dibuat belakangan.
  4. Log yang baru "diinstitusi" setelah insiden dimulai **tidak memenuhi** business records exception.
  5. Kompilasi data yang acak/selektif tidak diperkenankan.
  6. Log dipelihara secara rutin agar bisa dipakai sebagai bukti nantinya.
- **Rule 803, Federal Rules of Evidence** (records of regularly conducted activity): rekaman diterima bila dibuat pada/dekat waktu kejadian oleh (atau dari informasi yang dikirim oleh) seseorang yang punya pengetahuan; dipelihara dalam jalannya kegiatan rutin; pembuatan rekaman adalah praktik rutin; kondisi tersebut dibuktikan lewat kesaksian custodian atau sertifikasi (Rule 902(11)/(12)); dan lawan tidak membuktikan sumber informasi/metode persiapan yang tidak trustworthy.
- **Kesaksian custodian**: custodian (atau saksi terkualifikasi) harus bersaksi soal akurasi dan integritas log; tidak harus programmer perangkat lunak logging, tetapi harus mampu menjelaskan sistem yang dipakai, asal perangkat lunak, serta cara dan waktu rekaman dibuat. Catatan kegagalan atau kebocoran pada mesin pembuat log melemahkan bukti; log setelah titik mesin ditembus dinilai tersangkut paut (inherently suspected).
- **Catatan praktis**: original copies lebih disukai (print-out dari disk/tape dianggap original); software logging organisasi harus tersedia bagi pengadilan untuk diperiksa pihak lawan (kecuali ditetapkan trade secret dengan confidentiality order); rekaman sendiri yang justru melemahkan dalil bisa dipakai melawan organisasi.

### Enam Pedoman Kredibilitas Log
1. **Log everything** — konfigurasikan server untuk mencatat semua field yang tersedia; setiap field membantu rekonstruksi (mis. membuktikan asal trafik lewat backdoor proxy).
2. **Synchronize time** — sinkronkan jam semua mesin via NTP (protokol standar, UDP port 123, presisi milidetik) agar event lintas mesin bisa dikorelasikan; di Windows gunakan W32Time (lihat blok perintah).
3. **Use multiple sensors** — dua perangkat yang merekam fakta sama saling menguatkan kredibilitas; kombinasi log firewall + IDS + IPS bisa membuktikan IP tertentu mengakses server tertentu pada waktu tertentu.
4. **Missing logs** — pantau ketersediaan perangkat secara kontinyu; log yang hilang saat server terbukti online (via jadwal "canary hit" berkala) adalah indikasi penghapusan disengaja.
5. **Ensure system's integrity** — selalu terapkan service pack/hotfix dan audit semua perubahan file biner (mis. direktori Windows System) karena sistem menampung log; sistem yang dimodifikasi penyerang membuat lognya tidak sah.
6. **Control access to log files** — batasi izin akses (mis. NTFS permissions) dan audit akses; setelah file log ditutup, tidak ada proses yang boleh punya izin mengubah isinya.

### Autentisitas & Integritas Log
- Log umumnya teks sederhana — mudah diubah, timestamp-nya mudah dimodifikasi. Autentisitas harus **dibuktikan**: log dianggap sah hanya bila integritasnya terpelihara sejak awal pengumpulan.
- Jika server terkompromi, pindahkan log keluar dari server tersebut secepatnya.
- Alur standar: log dikirim ke **master log server**, lalu diarsipkan ke media sekunder/offline (DVD/disk terpisah).
- Integritas: enkripsi dengan skema public-key/PGP saat transfer; gunakan checksum/hash (mis. MD5/SHA-256, tools `md5sum`, `certutil`, Fsum) yang disimpan **bersama log** di lokasi terpisah; file signature mencegah korupsi satu file merusak validitas keseluruhan.
- Dokumentasikan semua transfer (siapa, kapan, hash) agar custodian bisa bersaksi di kemudian hari.

## Manajemen Log Terpusat
Ribuan perangkat dan aplikasi menghasilkan jutaan event per hari. Meninjau log satu per satu mustahil; solusinya **centralized log management**: mengumpulkan log dari berbagai perangkat ke satu lokasi untuk akses, analisis, dan review anomali yang cepat. Kapabilitasnya: pandangan 360° atas seluruh jaringan dari satu titik, alert berbasis metrik, dashboard yang bisa dibagikan, retensi policy per jenis log, serta ruang penyimpanan/backup historis yang besar — dan menjawab *who, what, when, where* atas sebuah event.

### Syslog
- Standar de-facto logging: protokol client/server untuk meneruskan pesan log lintas IP ke **syslog receiver** (syslog server/daemon/syslogd).
- Transport: UDP atau TCP (umumnya UDP 514; varian terenkripsi memakai TLS). Pesan dikirim dalam format cleartext; didukung sangat luas lintas platform.
- Keuntungan setup terpusat: server log berada di segmen berbeda (aman), log sulit dihapus oleh penyerang, pesan log memungkinkan korrelasi serangan lintas platform, dan kebijakan backup menjadi sederhana.

### Tiga Tier Infrastruktur Log
| Tier | Fungsi |
|------|--------|
| Log generation | Perangkat/aplikasi menghasilkan event |
| Log analysis & storage | Normalisasi, penyimpanan, indeks, korelasi |
| Log monitoring | Review berkelanjutan, alert, dashboard |

### Praktik Terbaik Centralized Logging
- Aktifkan logging di **semua** perangkat yang tersambung ke jaringan; pastikan admin bisa mendelegasikan akses ke tim keamanan saat darurat.
- Libatkan **departemen legal** saat menyusun kebijakan penyimpanan, pengambilan, dan analisis log.
- Pastikan transmisi dan penyimpanan log aman; struktur log konsisten; level severity alert jelas.
- Data yang disimpan harus mudah diakses saat investigasi — tanpa mengorbankan autentikasi/keamanan.
- Indexing dan penyimpanan incident log wajib, sebagai bahan korelasi dan referensi masa depan.

### Tantangan & Solusinya
| Tantangan | Rincian | Solusi |
|-----------|---------|--------|
| Banyak sumber log | Berbagai host/OS/aplikasi memproduksi log sendiri-sendiri | Definisikan requirement & goal log management di seluruh organisasi |
| Konten tak konsisten | Sumber A mencatat username tanpa IP; sumber B sebaliknya — sulit dihubungkan | Kebijakan & prosedur yang konsisten; audit berkala oleh personel kunci |
| Timestamp tak konsisten | Jam host salah → urutan event kacau (event M "30 detik sebelum" N padahal sebenarnya 1 menit sesudah) | NTP wajib; normalisasi timezone ke UTC |
| Format tak konsisten | TSV/CSV, XML, biner, database, proprietary; sebagian disimpan lokal, sebagian di-transfer | Normalisasi ke format standar; konversi otomatis |
| Perlindungan log | Log berisi kredensial/email; rentan diubah/dihancurkan; retensi bisa ter-overwrite | Enkripsi + kontrol akses; utilities untuk memperpanjang retensi |
| Analisis log | Tugas low-priority bagi admin; kurang pelatihan/automasi | Jadikan analisis proses proaktif; latih staf; siapkan infrastruktur aman |

## Korelasi Event
Korelasi event = menghubungkan sekumpulan event yang terjadi dalam **interval waktu tertentu** agar memberi makna baru: memilih sedikit event penting dari samudra event, dan menggantinya dengan event yang lebih bermakna. Biasanya dijalankan di platform log management dengan bantuan *event correlator* yang mengumpulkan event dari monitoring tool, elemen terkelola, dan sistem tiket.

- Contoh 1: 10 kegagalan login untuk satu user dalam 5 menit → memunculkan event "serangan keamanan".
- Contoh 2: suhu internal + eksternal melewati ambang dan event "device not responding" muncul dalam 5 detik → diganti event "device down due to overheating".

### Empat Langkah Korelasi
1. **Event aggregation** (de-duplication) — gabungkan event berulang menjadi satu agar tidak diduplikasi.
2. **Event masking** — sembunyikan event dari sistem downstream yang gagal akibat sistem hulu; hindari kekacauan saat crash/fail.
3. **Event filtering** — buang event yang tidak relevan.
4. **Root cause analysis** — langkah paling kompleks: identifikasi semua perangkat yang tak bisa diakses karena kegagalan jaringan, lalu kategorikan event menjadi **symptom events** (terkait perangkat tak terakses) dan **root cause events** (sisanya).

### Tipe & Prasyarat
- **Same-platform correlation** — satu OS umum di seluruh jaringan (mis. semua Windows); kumpulkan event log dan lakukan trend analysis.
- **Cross-platform correlation** — OS/hardware bercampur (klien Windows, firewall Linux, gateway email Linux); korelasi lintas platform.
- Tiga prasyarat sebelum korelasi berjalan:
  1. **Transmission of data** — log dipindahkan antar perangkat keamanan sampai titik konsolidasi; enkripsi + autentikasi wajib.
  2. **Normalization** — format log yang berbeda diformat ulang menjadi satu (atau polymorphic) schema yang mudah masuk database.
  3. **Data reduction** — kompresi, hapus duplikat, filter, gabungkan event serupa sebelum masuk mesin korelasi.

### Pendekatan Korelasi (ringkas)
| Pendekatan | Inti |
|------------|------|
| Graph-based | Komponen sistem = node, ketergantungan = edge; graf dipakai mencari root cause |
| Neural network-based | Jaringan saraf mendeteksi anomali dan root cause di event stream |
| Codebook-based | Seperti rule-based tetapi mengelompokkan event lewat codebook → eksekusi lebih cepat |
| Rule-based | Korelasi menurut aturan condition → action; mesin aturan mengolah sampai state final |
| Field-based | Bandingkan event spesifik pada satu/beberapa field data ternormalisasi |
| Automated field correlation | Bandingkan semua field secara sistematis (positif/negatif) lintas satu/lebih field |
| Packet parameter/payload | Korelasi paket dengan paket lain; bandingkan dengan signature serangan → daftar serangan baru potensial |
| Profile/fingerprint-based | Data forensik (OS fingerprint, port scan terisolasi, banner snatching) → profil penyerang; deteksi relay/host terkompromi/sama penyerang di lokasi lain |
| Vulnerability-based | Petakan event IDS ke host rentan via vulnerability scanner; deduksi serangan dan prioritaskan respons |
| Open-port-based | Estimasi peluang serangan sukses dengan membandingkan daftar port terbuka host vs port yang diserang |
| Bayesian | Statistik + teori probabilitas (dua variabel); memprediksi langkah penyerang berikutnya |
| Time/clock/role-based | Pantau perilaku komputer dan penggunanya; alert saat anomali muncul |
| Route correlation | Ekstrak informasi rute serangan dan gunakan untuk melacak data terkait serangan lain |

## Perintah
### tshark — analisis paket
```bash
# Potret umum: statistik & percakapan
tshark -r capture.pcap -q -z io,stat
tshark -r capture.pcap -q -z conv,tcp
# HTTP: host & URI yang diminta
tshark -r capture.pcap -Y http -T fields -e http.host -e http.request.uri
# DNS: daftar domain yang ditanya, dengan frekuensi
tshark -r capture.pcap -Y dns -T fields -e dns.qry.name | sort | uniq -c | sort -rn
# TLS: SNI tujuan (metadata yang masih terbaca)
tshark -r capture.pcap -Y "tls.handshake.type == 1" -T fields -e tls.handshake.extensions_server_name
# Beaconing heuristic: SYN paling sering ke ip.dst
tshark -r capture.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0" \
  -T fields -e ip.dst | sort | uniq -c | sort -rn | head
# Lateral movement: SMB2 Write & DCOM RPC
tshark -r capture.pcap -Y "smb2.cmd == 0x05" -T fields -e ip.src -e ip.dst -e smb2.filename
tshark -r capture.pcap -Y "dcerpc.opnum == 38" -T fields -e ip.src -e ip.dst
# Timeline
tshark -r capture.pcap -T fields -e frame.time -e ip.src -e ip.dst -e _ws.col.Protocol -e _ws.col.Info
```

### Sinkronisasi waktu (NTP & W32Time)
```bash
# Linux: verifikasi sinkronisasi
ntpq -p                 # daftar peer NTP (kolom reach/jitter)
chronyc tracking        # ringkasan drift saat ini (chrony)

# Windows: status & konfigurasi W32Time
w32tm /query /status
w32tm /config /manualpeerlist:"time.cloudflare.com,0x9" /syncfromflags:manual /update
w32tm /resync

# Registry W32Time untuk sumber waktu eksternal (standalone server):
# Key:   HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
#   Type      = NTP        (REG_SZ)
#   NtpServer = <host ntp> (REG_SZ), mis. tock.usno.navy.mil
#   Period    = 24         (REG_SZ)
```

### Hash & enkripsi log (integritas)
```bash
# Linux: hash sebelum & sesudah transfer; simpan bersama log
sha256sum syslog-2026-10-29.log | tee syslog-2026-10-29.log.sha256
md5sum    syslog-2026-10-29.log | tee syslog-2026-10-29.log.md5

# Windows: hash via certutil
certutil -hashfile firewall.log SHA256

# Fsum (SlavaSoft) — 13 pilihan algoritma hash/checksum
fsum -md5 log.tar.gz

# Enkripsi untuk transfer (PGP/GPG)
gpg -c syslog-2026-10-29.log                              # simetris
gpg -e -r analyst@example.org syslog-2026-10-29.log       # public-key
```

### Log terpusat & canary (kesiapan)
```bash
# Uji jalur syslog ke server terpusat
logger -n 10.10.9.5 -P 514 -d "readiness-test $(date -u +%FT%TZ)"

# rsyslog: teruskan semua log ke collector
echo '*.* @10.10.9.5:514' > /etc/rsyslog.d/90-forward.conf && systemctl restart rsyslog

# Canary berkala: bukti server online saat log hilang (indikasi penghapusan)
( while :; do curl -sk -o /dev/null -w '%{http_code} %{time_total}\n' \
    https://server.example/health | ts >> /var/log/readiness/canary.log; sleep 300; done ) &

# Cek perangkat yang logging-nya mati (contoh rsyslog client)
rg -n "imjournal|omfwd" /etc/rsyslog.conf /etc/rsyslog.d/ || echo "forwarding tidak terkonfigurasi"
```

## Workflow / Alur Kerja
1. **Kumpulkan sumber data** — PCAP dari tap/span, flow record, log firewall/IDS/IPS, log DNS, syslog terpusat. Setiap sumber punya zona waktu berbeda — standarkan UTC.
2. **Amankan bukti** — hash setiap log/PCAP saat diterima, catat di chain of custody, salin ke master log server/media offline bila host terkompromi.
3. **Potret umum** — statistik volume, percakapan TCP teratas, protokol dominan.
4. **Fokus ke host terdampak** — filter per IP; lihat percakapan masuk/keluar.
5. **Deteksi anomaly & IoC** — beaconing, scan, transfer besar, koneksi ke IP tak dikenal, traffic di port tak wajar, anomali login (correlate threat intel).
6. **Ekstrak file** — export-objects HTTP/SMB bila trafik tidak terenkripsi.
7. **Korelasikan event lintas sumber** — de-dup → masking → filtering → root cause analysis; gabungkan sisi jaringan dengan artefak host (proses, akun, scheduled task).
8. **Korelasi ke timeline & laporan** — bungkus temuan IP/waktu ke timeline global; catat apakah temuan berasal dari flow, PCAP, atau keduanya.

## Common Pitfalls / Kesalahan Umum
- ⚠️ **Waktu capture vs waktu dianalisis** — paket yang tidak ter-capture menutup celah investigasi; pastikan capture di choke point yang relevan.
- ⚠️ **Asumsi trafik terenkripsi = aman** — metadata TLS (SNI, interval) tetap informatif.
- ⚠️ **Lupa normalisasi timezone** — PCAP, firewall log, SIEM sering beda zona; konsistenkan ke UTC dan catat drift jam host.
- ⚠️ **Hanya melihat alert IDS** — IDS menangkap signature yang dikenal; pola baru & anomaly sering lewat. Tidak ada alert ≠ tidak ada serangan.
- ⚠️ **Filter terlalu luas** — `grep tcp` menghasilkan ribuan paket; persempit ke IP/port relevan.
- ⚠️ **Log tinggal di host terkompromi** — penyerang bisa mengedit/menghapusnya; pindahkan ke master log server segera.
- ⚠️ **Tidak ada hash saat akuisisi** — tanpa hash, autentisitas log mudah diserang balik di persidangan.
- ⚠️ **Retensi kehabisan** — log lama ter-overwrite sebelum sempat dianalisis; sesuaikan kebijakan retensi per jenis log.
- ⚠️ **Jam host tidak sinkron** — tanpa NTP, kronologi lintas sumber kacau dan korelasi jadi tidak bisa diandalkan.

## Cross-references / Referensi Silang
- [00 Methodology](../cheatsheets/00-methodology.md) — tahapan investigasi end-to-end.
- [01 Chain of Custody](../cheatsheets/01-chain-of-custody.md) — perwalian & dokumentasi hash log/PCAP.
- [05 Memory Forensics](../cheatsheets/05-memory-forensics.md) — koneksi aktif di RAM vs PCAP.
- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — artefak host yang menunjuk tujuan jaringan.
- [11 Report Writing](../cheatsheets/11-report-writing.md) — cara menyajikan temuan & bukti log di laporan.
- [`tools/network/tshark-oneliners.sh`](../tools/network/tshark-oneliners.sh) — oneliner siap pakai.
- [`docs/glossary.md`](../docs/glossary.md) — istilah forensik jaringan (korelasi event, syslog, dsb.).
- `templates/` — formulir Chain of Custody & Forensic Report untuk mendokumentasikan log.

## Contoh: Deteksi Beaconing / Worked Example
Sebuah organisasi mencurigai salah satu workstation terinfeksi. Tim sudah menerima PCAP dua jam dari span port pada switch akses. Pertanyaan investigasinya: apakah host tersebut berkomunikasi dengan C2, dan jika ya, ke mana?

Langkah pertama adalah mempersempit data ke host yang dicurigai: `tshark -r capture.pcap -Y "ip.addr == 10.10.4.37"`. Dari situ terlihat bahwa host memang aktif berkomunikasi ke internet, tetapi sebagian besar trafiknya adalah HTTP biasa ke domain populer. Langkah kedua adalah melihat distribusi tujuan dengan menghitung kemunculan alamat IP, lalu mengurutkan dari yang paling sering.

Hasilnya menunjukkan satu IP eksternal yang muncul ratusan kali, jauh lebih sering daripada tujuan lain. Langkah ketiga adalah memeriksa pola waktu: dengan `-T fields -e frame.time -e ip.dst` dan filter ke IP tersebut, terlihat koneksi berulang dengan interval sekitar 60 detik, dengan ukuran payload kecil dan seragam. Pola seperti ini sangat khas beacon, bukan trafik pengguna biasa.

Langkah keempat adalah memeriksa metadata TLS. ClientHello menunjukkan SNI berupa domain yang tidak lazim, baru terdaftar beberapa minggu sebelumnya. Informasi ini memperkuat dugaan C2, meskipun isi trafik tidak bisa dibaca karena terenkripsi. Langkah kelima adalah mencari host lain yang menghubungi IP yang sama; ternyata ada tiga host lain dengan pola serupa, yang memperluas cakupan insiden.

Langkah terakhir adalah mendokumentasikan semuanya: IP, domain, waktu pertama dan terakhir terlihat, jumlah koneksi, ukuran payload rata-rata, dan daftar host terdampak. Temuan ini kemudian dikorelasikan dengan artefak host (proses, scheduled task) untuk menemukan sumber infeksi. Tanpa PCAP, pola beaconing ini mungkin tidak akan terlihat sama sekali.

## Contoh: Korelasi Event Brute-Force
Log auth menunjukkan belasan kegagalan login SSH untuk akun `svc-backup` dari IP eksternal 203.0.113.77 dalam empat menit. Korelasi dimulai dari **aggregation**: event gagal-login berulang digabung menjadi satu event "percobaan brute-force". **Filtering** membuang alert CPU monitoring yang kebetulan pada jam sama karena tidak berhubungan. **Masking** menyembunyikan alert downstream dari host lain yang fail-over akibat layanan auth sibuk. **Root cause analysis** menyimpulkan akar masalah: percobaan brute-force ke satu akun service, bukan gangguan infrastruktur.

Tindak lanjut: blokir IP pada firewall, tarik PCAP segmen yang relevan untuk memeriksa payload login, cocokkan dengan `auth.log`/Event ID 4625 di host tujuan, dan tambahkan IP ke watchlist SIEM. Semua temuan dicantumkan ke timeline dengan timestamp UTC, dan log yang dipakai sebagai bukti di-hash serta dicatat di chain of custody.

## Checklist
- [ ] Sumber data dicatat: PCAP, flow, firewall, DNS, proxy, syslog.
- [ ] Semua timestamp dinormalisasi ke UTC; sinkronisasi NTP diverifikasi dan drift dicatat.
- [ ] Setiap log/PCAP diberi hash saat diterima dan tercatat di chain of custody.
- [ ] Log disalin ke master log server / media offline bila host terkompromi.
- [ ] Akses ke file log dibatasi; siapa yang membuka dicatat (audit).
- [ ] Statistik protokol dan percakapan teratas dibuat.
- [ ] Host terdampak difilter dan dianalisis terpisah.
- [ ] Pola beaconing, scanning, dan transfer besar diperiksa.
- [ ] IoC jaringan dicari lintas log: port tak wajar, lonjakan outbound, anomali login, user-agent aneh.
- [ ] Korelasi event dijalankan: de-dup, masking, filtering, root cause analysis.
- [ ] File hasil ekstraksi diberi hash dan dirujuk ke EV-ID.
- [ ] Temuan dikorelasikan dengan artefak host dan laporan.

## Pertanyaan Umum / FAQ
**Apakah trafik terenkripsi membuat analisis mustahil?** Tidak. Metadata seperti SNI, ukuran paket, durasi, dan interval masih sangat informatif. Untuk kasus tertentu, kunci TLS mungkin tersedia dari endpoint, tetapi jangan mengandalkannya.

**Bagaimana menangani PCAP berukuran ratusan GB?** Gunakan filter capture (BPF) saat pengambilan, atau proses dengan `editcap` untuk memotong per jendela waktu. Hindari membuka file besar langsung di Wireshark GUI.

**Apakah DNS log cukup tanpa PCAP?** Sering cukup untuk menunjukkan domain yang dihubungi, tetapi tidak menunjukkan volume data atau pola koneksi. Gunakan DNS log sebagai pintu masuk, lalu lengkapi dengan flow atau PCAP.

**Penyerang bisa saja mengubah log — bagaimana membuktikan autentisitasnya?** Kombinasi: hash saat akuisisi (custodian bisa bersaksi log tak berubah), penerusan otomatis ke syslog server di segmen terpisah, arsip offline, dan kesaksian custodian tentang sistem logging yang dipakai. Log yang dibuat setelah insiden tidak memenuhi kriteria business records — makanya logging harus menjadi rutinitas sejak lama.

**Berapa lama log harus disimpan?** Ikuti kebijakan organisasi dan regulasi yang berlaku; catat trade-off antara biaya penyimpanan dan kebutuhan investigasi retroaktif. Log kecil bernilai tinggi (auth, DNS, proxy, flow) murah untuk disimpan lebih lama; full PCAP biasanya berumur pendek dengan retensi terukur.

## Alur Kerja Flow vs PCAP / Flow-first Workflow
Pada jaringan besar, tidak realistis menyimpan PCAP penuh untuk semua trafik. Pendekatan yang lazim adalah flow-first: mulai dari flow record untuk menemukan anomali, lalu ambil PCAP hanya untuk host dan jendela waktu yang relevan.

1. **Agregasi flow** — kumpulkan NetFlow/IPFIX dari router atau firewall, minimal metadata: source, destination, port, byte count, dan waktu.
2. **Deteksi anomali** — cari pola one-to-many (scanning), many-to-one (DDoS), atau koneksi periodik dengan ukuran kecil (beacon).
3. **Persempit waktu dan host** — buat daftar host dan jendela waktu yang mencurigakan.
4. **Ambil PCAP** — jika tersedia retensi PCAP, tarik hanya segmen yang relevan. Jika tidak, gunakan log firewall dan proxy sebagai pengganti.
5. **Verifikasi** — konfirmasi temuan flow dengan detail paket, lalu korelasikan ke artefak host.

Pendekatan ini menghemat storage sekaligus menjaga kualitas analisis. Yang penting adalah mendokumentasikan sumber data di laporan: apakah temuan berasal dari flow, PCAP, atau keduanya.

## Zeek dan Log Jaringan / Zeek Logs
Selain PCAP, Zeek (dahulu Bro) menghasilkan log terstruktur yang sangat berguna untuk investigasi berskala besar. Zeek membaca trafik dan menulis file seperti `conn.log`, `dns.log`, `http.log`, `ssl.log`, dan `files.log`. Setiap baris adalah satu event dengan timestamp, host asal, host tujuan, dan metadata lain.

Keunggulannya: log ini bisa diproses dengan grep, awk, atau SQL tanpa perlu membuka PCAP. Contoh sederhana untuk mencari domain yang paling sering ditanya: agregasi `dns.log` berdasarkan kolom query, lalu urutkan dari yang terbanyak. Untuk mencari transfer file besar, periksa `files.log` dan jumlah byte per koneksi.

Zeek juga mendukung script kustom untuk mendeteksi pola tertentu, misalnya koneksi berulang ke satu host dengan interval pendek. Namun untuk investigasi cepat, log bawaan sudah cukup untuk memberi arah. Yang penting, simpan log Zeek bersama PCAP dan catat konfigurasinya — pembaca laporan perlu tahu apakah sensor melihat trafik penuh atau hanya sebagian.

Jika organisasi memakai IDS seperti Suricata, log alert juga bisa dipakai sebagai titik masuk. Tetapi ingat: tidak adanya alert bukan berarti tidak ada serangan. Signature hanya menangkap pola yang sudah dikenal, sedangkan investigasi forensik justru sering menemukan pola baru.

## Referensi / References
1. tshark / Wireshark Docs — https://www.wireshark.org/docs/
2. Zeek Documentation — https://docs.zeek.org/
3. RFC 793 — Transmission Control Protocol (TCP) — https://www.rfc-editor.org/rfc/rfc793
4. RFC 3227 — Guidelines for Evidence Collection and Archiving — https://www.rfc-editor.org/rfc/rfc3227
5. RFC 5424 — The Syslog Protocol — https://www.rfc-editor.org/rfc/rfc5424
6. RFC 5905 — Network Time Protocol Version 4 — https://www.rfc-editor.org/rfc/rfc5905
7. NIST SP 800-92 — Guide to Computer Security Log Management — https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-92.pdf
8. NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response — https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-86.pdf
9. Federal Rules of Evidence, Rule 803 — https://www.rulesofevidence.org/article-viii/

---
**Last updated**: 2026-10-29 · **Maintained by**: @cingmen

