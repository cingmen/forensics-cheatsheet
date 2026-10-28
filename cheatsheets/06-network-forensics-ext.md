# Network Forensics Cheatsheet (Ekstensi) / Cheatsheet Forensik Jaringan (Ekstensi)
> **TL;DR**: Ekstensi materi modul 08 Network Forensics — topik tambahan: filter canggih tshark, analyse alirasi protokol, IoC jaringan lanjutan, dan playbook korelasi lintas sumber. Semua ditarik dari materi pelatihan *Network Forensics* (312-49, Modul 08, rev. 2024-06-20) dan menulis ulang dalam kata sendiri.

## Topik Tambahan / Additional Topics

### Filter Tshark Canggih / Advanced tshark Filters
Berikut filter tambahan yang bisa digunakan saat menganalisis PCAP dengan tshark, bukan merupakan duplikat dari yang ada di cheatsheet utama melainkan memperluas kemampuan filter:

| Tujuan | Perintah tshark | Catatan |
|--------|-----------------|---------|
| **Filter HTTP metode spesifik** | `tshark -r capture.pcap -Y "http.request.method == \"POST\""` | Gunak untuk mendeteksi upload/ekstrasilasi via POST |
| **Filter HTTP status code** | `tshark -r capture.pcap -Y "http.response.code == 404"` | Mencari request yang menghasilkan error 404 |
| **Filter MQTT koneksi** | `tshark -r capture.pcap -Y "mqtt"` | Protokol IoT yang jarang dilihat tapi sering digunakan C2 |
| **Filter protocol UDP lengkap** | `tshark -r capture.pcap -Y "udp.srcport == 53"` | Filter DNS over UDP |
| **Filter TCP flags kombinasi** | `tshark -r capture.pcap -Y "tcp.flags == 0x12"` | FLAGS SYN+ACK (cek handshake) |
| **Filter SMB2 dialect** | `tshark -r capture.pcap -Y "smb2.dialect"` | Mendeteksi versi SMB yang digunakan |
| **Filter ICMP type** | `tshark -r capture.pcap -Y "icmp.type == 8"` | ICMP request (ping) |
| **Filter ICMP reply** | `tshark -r capture.pcap -Y "icmp.type == 0"` | ICMP reply (pong) |
| **Filter ARP request** | `tshark -r capture.pcap -Y "arp"` | Monitoring lalu lintas ARP |
| **Filter TLS version** | `tshark -r capture.pcap -Y "tls.handshake.version == \"TLSv1.3\""` | Cek versi TLS yang digunakan |
| **Filter HTTP User-Agent aneh** | `tshark -r capture.pcap -Y "http.user_agent contains \"python\" "` | Mencari user-agent tool otomatis |
| **Filter DNS respons codes** | `tshark -r capture.pcap -Y "dns.rcode == 3"` | DNS name error |
| **Filter TCP stream** | `tshark -r capture.pcap -Y "tcp.stream eq 5"` | Lihat alur TCP tertentu |

### IoC Jaringan Lanjutan / Advanced Network IoC

| IoC | Artinya | Indikator Kunci | Log Sumber |
|-----|---------|-----------------|-----------|
| **Domain Dynamic DNS** | Domain yang baru terdaftar dan langsung diupdate ke IP dinamis | Masa aktif domain < 24 jam + IP perubahan cepat | DNS, WHOIS |
| **TLD tak wajar** | Top-level domain yang tidak biasa untuk organisasi (.top, .xyz, .gq) | Banyak sub-domain di bawah TLD one-check | DNS proxy |
| **Port scanning cepat** | Port scan dengan interval < 1 detik | Pola SYN ke banyak port target | Firewall, IDS |
| **Beacon dengan jitter variatif** | C2 yang mengubah interval waktu kirim | Interval 25-35 detik, lalu 55-65 detik | PCAP, flow |
| **TLS handshake tanpa data** | Handshake TLS tapi tidak ada application data berikutnya | ClientHello tanpa ServerName extention | tshark TLS filter |
| **Koneksi ke IP hitam** | Koneksi ke IP yang berada di blacklist threat intel | IP cocok dengan OpenPhish/AbuseIP | Firewall, SIEM |
| **DNS tunneling indikasi** | Ukuran paket DNS aneh (> 512 byte) atau many query ke domain sama | Panjang payload DNS > normal | DNS log, Zeek dns.log |
| **SMB relay attack** | Penyerang menggunakan respons SMB target untuk autentikasi ke host lain | Permintaan SMB Sign+Seal aneh | SMB2 log, tshark |
| **Port-forwarding internal ke external** | Traffic internal keluar lewat port 80/443 ke IP eksternal | Pola one-to-many dari internal ke IP luar | Firewall log, NetFlow |

### Workflow Korelasi Lintas Sumber / Cross-Source Correlation Playbook

Langkah-ringkas untuk mengkombinasikan data jaringan dengan artefak host:

```
SETUP:
1. Hash semua PCAP/flow saat diterima → simpan di chain of custody
2. Normalisasi zona waktu ke UTC + catat drift NTP
3. Siapkan master log server dengan retensi minimal 90 hari

STEP 1: AGREGASI
- Kumpulkan: PCAP dari span port, NetFlow dari router, log firewall/IDS, Zeek logs, syslog
- De-dup event berdasarkan frame/time stamp
- Filter: buang duplicate, fokus ke host/IP mencurigai

STEP 2: MASKING
- Sembunyikan detail identitas di sistem downstream
- Jaga integritas log asli di lokasi terpisah
- Contoh: copy PCAP ke server analisis, jangan langsung di-edit di host asal

STEP 3: FILTERING
- Filter per protokol: hanya HTTP/HTTPS, skip DNS internal
- Filter per IP: fokus ke IP eksternal/host mencurigai
- Filter per port: cari port tak wajar/abnormal

STEP 4: ROOT CAUSE ANALYSIS
- Gabungkan hasil dengan artefak host:
  * PCAP → destination IP, waktu koneksi, ukuran payload
  * Flow → byte count, duration, protocol distribusi
  * Zeek conn.log → duration, bytes, status code
  * Auth log → failed login, successful login, source IP
  * File integrity → perubahan file sistem mencurigai
- Identifikasi: symptom events vs root cause events
- Dokumentasikan jalur serangan dari entry point ke target akhir

STEP 5: TIMELINE & LAPORAN
- Susun timeline global dengan timestamp UTC
- Tandai: source of each finding (PCAP/flow/host artifact)
- Referensi ke EV-ID atau kasus number
- Sertakan hash bukti & catatan custodian