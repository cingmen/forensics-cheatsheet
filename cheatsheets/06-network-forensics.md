# Network Forensics Cheatsheet / Cheatsheet Forensik Jaringan

> **TL;DR**: Analisis paket (PCAP) dan log flow jaringan: filter tshark untuk HTTP/DNS/TLS/SMB, deteksi beaconing dan lateral movement, serta alur dari capture sampai timeline.

## Overview / Gambaran Umum

Forensik jaringan menjawab pertanyaan yang tidak bisa dijawab host saja: dengan siapa server berkomunikasi, pada jam berapa, mengirim data berukuran berapa, dan apakah polanya wajar. Sumber datanya beragam: full PCAP (tshark/Wireshark), flow record (NetFlow/mimic), IDS alerts (Suricata/Zeek), dan firewall logs.

Pendekatan praktisnya berlapis: mulai dari potret umum (statistik per protokol / percakapan), turun ke filter spesifik (HTTP POST, DNS query, TLS handshake), lalu lanjut ke deteksi anomaly — beaconing, scanning, data exfiltration, lateral movement via SMB/RPC. Setiap temuan dihubungkan ke timeline global investigasi.

Perlu diingat: trafik modern sebagian besar terenkripsi (TLS). Meski isi tidak dibaca, metadata sering informatif: SNI, ukuran paket, interval, tujuan. Untuk kasus eksfiltrasi, ukuran dan waktu koneksi sering cukup untuk membangun kronologi.

## Key Concepts / Konsep Kunci

### PCAP vs Flow / Capture Penuh vs Flow

- **PCAP** — capture paket penuh; bisa dibaca ulang isi, tapi mahal storage dan CPU.
- **Flow record (NetFlow/IPFIX)** — hanya metadata percakapan, jauh lebih ringan, umumnya di topologi besar. - Investigasi memadukan keduanya: flow untuk skala besar, PCAP untuk deep-dive di host tertentu.

### Beaconing / Pola Koneksi Berulang

- C2 beacon biasanya tampil sebagai koneksi berulang ke satu host pada interval serupa (30–300 detik).
- Jitter (variasi interval kecil) tidak menghapus pola; agregasi per 1–5 menit menggarisbawahi beacon.
- Indikator umum: SYN berulang ke satu IP dengan payload kecil dan interval serupa, kadang di luar jam kerja.

### Data Exfiltration & Lateral Movement / Keluarnya Data & Gerak Samping

- Eksfiltrasi klasik: upload besar ke host baru (S3 FTP, HTTP POST besar), biasanya di luar jam kerja.
- Lateral movement sering pakai SMB (PSEXec, admin share), RPC, atau RDP — tampil sebagai koneksi SMB2 ke banyak host internal dari satu host diserang.
- Deteksi berbasis flow: pola "one-to-many" SMB dari satu sumber adalah tanda lateral movement yang jelas.

## Commands / Perintah

```bash
# Potret umum: statistik & percakapan
tshark -r capture.pcap -q -z io,stat
tshark -r capture.pcap -q -z conv,tcp

# HTTP: host & URI yang diminta
tshark -r capture.pcap -Y http -T fields -e http.host -e http.request.uri

# DNS: daftar domain yang ditanya, dg menghitung
tshark -r capture.pcap -Y dns -T fields -e dns.qry.name | sort | uniq -c | sort -rn

# TLS: SNI tujuan (metadata yang masih terbaca)
tshark -r capture.pcap -Y "tls.handshake.type == 1" -T fields -e tls.handshake.extensions_server_name

# Beaconing heuristic: SYN sebagai ip.dst, most-repeated
tshark -r capture.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0" \
       -T fields -e ip.dst | sort | uniq -c | sort -rn | head

# Lateral movement: SMB2 Write & DCOM RPC
tshark -r capture.pcap -Y "smb2.cmd == 0x05" -T fields -e ip.src -e ip.dst -e smb2.filename
tshark -r capture.pcap -Y "dcerpc.opnum == 38" -T fields -e ip.src -e ip.dst

# Timeline
tshark -r capture.pcap -T fields -e frame.time -e ip.src -e ip.dst -e _ws.col.Protocol -e _ws.col.Info
```

## Workflow / Alur Kerja

1. **Kumpulkan sumber data** — PCAP dari tap/span, flow record, log firewall/IDS, log DNS. Setiap sumber punya waktu & Zona waktu berbeda — standarkan UTC.
2. **Potret umum** — statistik unduhan, percakapan TCP top, protokol yang dominan.
3. **Fokus ke host terdampak** — filter per IP; lihat percakapan masuk/keluar.
4. **Deteksi anomaly** — beaconing, scan, data transfer besar, koneksi ke IP unknown (correlate threat intel).
5. **Ekstrak file** — export-objects HTTP/SMB bila trafik tidak terenkripsi.
6. **Korelasi ke timeline** — bungkus temuan IP/waktu ke timeline global; hubungkan ke artefak host (proses, akun).

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Waktu capture vs waktu dianalisis** — paket yang tidak captured dapat menutup celah investigasi; pastikan capture berada di choke point yang relevan.
- ⚠️ **Asumsi trafik terenkripsi = aman** — metadata TLS (SNI, interval) masih informatif; jangan acuh tak acuh.
- ⚠️ **Lupa normalisasi timezone** — PCAP, firewall log, SIEM sering beda zona; konsistenkan ke UTC.
- ⚠️ **Hanya melihat alert IDS** — IDS menangkap signature; pola anomaly sering di luar signature set.
- ⚠️ **Filter terlalu luas** — mit grep "tcp" menghasilkan ribuan paket; luruskan ke IP/port yang relevan.

## Cross-references / Referensi Silang

- [05 Memory Forensics](../cheatsheets/05-memory-forensics.md) — koneksi aktif di RAM vs PCAP.
- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — artefak host yang menunjuk tujuan jaringan.
- [`tools/network/tshark-oneliners.sh`](../tools/network/tshark-oneliners.sh) — oneliner siap pakai.

## Contoh Deteksi Beaconing / Worked Example

Sebuah organisasi mencurigai salah satu workstation terinfeksi. Tim sudah menerima PCAP dua jam dari span port pada switch akses. Pertanyaan investigasinya: apakah host tersebut berkomunikasi dengan C2, dan jika ya, ke mana?

Langkah pertama adalah mempersempit data ke host yang dicurigai: `tshark -r capture.pcap -Y "ip.addr == 10.10.4.37"`. Dari situ terlihat bahwa host memang aktif berkomunikasi ke internet, tetapi sebagian besar trafiknya adalah HTTP biasa ke domain populer. Langkah kedua adalah melihat distribusi tujuan dengan menghitung kemunculan alamat IP, lalu mengurutkan dari yang paling sering.

Hasilnya menunjukkan satu IP eksternal yang muncul ratusan kali, jauh lebih sering daripada tujuan lain. Langkah ketiga adalah memeriksa pola waktu: dengan `-T fields -e frame.time -e ip.dst` dan filter ke IP tersebut, terlihat koneksi berulang dengan interval sekitar 60 detik, dengan ukuran payload kecil dan seragam. Pola seperti ini sangat khas beacon, bukan trafik pengguna biasa.

Langkah keempat adalah memeriksa metadata TLS. ClientHello menunjukkan SNI berupa domain yang tidak lazim, baru terdaftar beberapa minggu sebelumnya. Informasi ini memperkuat dugaan C2, meskipun isi trafik tidak bisa dibaca karena terenkripsi. Langkah kelima adalah mencari host lain yang menghubungi IP yang sama; ternyata ada tiga host lain dengan pola serupa, yang memperluas cakupan insiden.

Langkah terakhir adalah mendokumentasikan semuanya: IP, domain, waktu pertama dan terakhir terlihat, jumlah koneksi, ukuran payload rata-rata, dan daftar host terdampak. Temuan ini kemudian dikorelasikan dengan artefak host (proses, scheduled task) untuk menemukan sumber infeksi. Tanpa PCAP, pola beaconing ini mungkin tidak akan terlihat sama sekali.

## Alur Kerja Flow vs PCAP / Flow-first Workflow

Pada jaringan besar, tidak realistis menyimpan PCAP penuh untuk semua trafik. Pendekatan yang lazim adalah flow-first: mulai dari flow record untuk menemukan anomali, lalu ambil PCAP hanya untuk host dan jendela waktu yang relevan.

1. **Agregasi flow** — kumpulkan NetFlow/IPFIX dari router atau firewall, minimal metadata: source, destination, port, byte count, dan waktu.
2. **Deteksi anomali** — cari pola one-to-many (scanning), many-to-one (DDoS), atau koneksi periodik dengan ukuran kecil (beacon).
3. **Persempit waktu dan host** — buat daftar host dan jendela waktu yang mencurigakan.
4. **Ambil PCAP** — jika tersedia retensi PCAP, tarik hanya segmen yang relevan. Jika tidak, gunakan log firewall dan proxy sebagai pengganti.
5. **Verifikasi** — konfirmasi temuan flow dengan detail paket, lalu korelasikan ke artefak host.

Pendekatan ini menghemat storage sekaligus menjaga kualitas analisis. Yang penting adalah mendokumentasikan sumber data di laporan: apakah temuan berasal dari flow, PCAP, atau keduanya.

## Checklist Analisis Jaringan / Network Analysis Checklist

- [ ] Sumber data dicatat: PCAP, flow, firewall, DNS, proxy.
- [ ] Semua timestamp dinormalisasi ke UTC.
- [ ] Statistik protokol dan percakapan teratas dibuat.
- [ ] Host terdampak difilter dan dianalisis terpisah.
- [ ] Pola beaconing, scanning, dan transfer besar diperiksa.
- [ ] File hasil ekstraksi diberi hash dan dirujuk ke EV-ID.
- [ ] Temuan dikorelasikan dengan artefak host dan laporan.

## Pertanyaan Umum / FAQ

**Apakah trafik terenkripsi membuat analisis mustahil?** Tidak. Metadata seperti SNI, ukuran paket, durasi, dan interval masih sangat informatif. Untuk kasus tertentu, kunci TLS mungkin tersedia dari endpoint, tetapi jangan mengandalkannya.

**Bagaimana menangani PCAP berukuran ratusan GB?** Gunakan filter capture (BPF) saat pengambilan, atau proses dengan `editcap` untuk memotong per jendela waktu. Hindari membuka file besar langsung di Wireshark GUI.

**Apakah DNS log cukup tanpa PCAP?** Sering cukup untuk menunjukkan domain yang dihubungi, tetapi tidak menunjukkan volume data atau pola koneksi. Gunakan DNS log sebagai pintu masuk, lalu lengkapi dengan flow atau PCAP.

## Zeek dan Log Jaringan / Zeek Logs

Selain PCAP, Zeek (dahulu Bro) menghasilkan log terstruktur yang sangat berguna untuk investigasi berskala besar. Zeek membaca trafik dan menulis file seperti `conn.log`, `dns.log`, `http.log`, `ssl.log`, dan `files.log`. Setiap baris adalah satu event dengan timestamp, host asal, host tujuan, dan metadata lain.

Keunggulannya: log ini bisa diproses dengan grep, awk, atau SQL tanpa perlu membuka PCAP. Contoh sederhana untuk mencari domain yang paling sering ditanya: agregasi `dns.log` berdasarkan kolom query, lalu urutkan dari yang terbanyak. Untuk mencari transfer file besar, periksa `files.log` dan jumlah byte per koneksi.

Zeek juga mendukung script kustom untuk mendeteksi pola tertentu, misalnya koneksi berulang ke satu host dengan interval pendek. Namun untuk investigasi cepat, log bawaan sudah cukup untuk memberi arah. Yang penting, simpan log Zeek bersama PCAP dan catat konfigurasinya — pembaca laporan perlu tahu apakah sensor melihat trafik penuh atau hanya sebagian.

Jika organisasi memakai IDS seperti Suricata, log alert juga bisa dipakai sebagai titik masuk. Tetapi ingat: tidak adanya alert bukan berarti tidak ada serangan. Signature hanya menangkap pola yang sudah dikenal, sedangkan investigasi forensik justru sering menemukan pola baru.

## References / Referensi

1. tshark / Wireshark Docs — https://www.wireshark.org/docs/
2. Zeek Documentation — https://docs.zeek.org/
3. RFC 793 — Transmission Control Protocol (TCP) — https://www.rfc-editor.org/rfc/rfc793
4. RFC 3227 — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
