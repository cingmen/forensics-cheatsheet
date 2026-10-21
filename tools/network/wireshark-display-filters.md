# Wireshark Display Filters / Ref Display Filter Wireshark

> **TL;DR**: Kumpulan display filter Wireshark yang paling dirujuk saat investigasi jaringan — dari TCP dan HTTP sampai TLS dan SMB2.

## Overview

Display filter di Wireshark/tshark memfilter packet yang ditampilkan — berbeda dari capture filter (BPF) yang memfilter paket saat capture. Yang khas: operator pakai `==` dan simbol logis `&&/||/!`, bukan `and/or` klasik. Peserta kelas DFIR sangat sering berpusing di sini; cheatsheet ini meringkas filter yang paling berguna.

## Filter Dasar / Basic Filters

```text
ip.addr == 10.0.0.5            # hanya paket berasal/dikirm ke IP ini
ip.src == 10.0.0.5 && ip.dst == 10.0.0.9
tcp.port == 443                # TCP port 443 (dua arah)
udp.port == 53                 # DNS
tcp.flags.syn == 1 && tcp.flags.ack == 0   # SYN pertama (scan/beacon triage)
tcp.flags.reset == 1           # RST (intruder anomaly)
http                           # HTTP traffic
tls                            # TLS traffic
dns                            # DNS queries
```

## Filter Investigasi / Investigation Filters

```text
# Error/failed traffic aluminum
tcp.analysis.flags            # paket bermasalah: retransmission, dup ack, dsb
tcp.analysis.retransmission    # retransmission saja

# HTTP utama lalu body
http.request.method == "POST"
http.request.uri contains "login"
http.file_data                # HTTP body payload

# DNS anomalies
dns.flags.response == 0        # query saja
dns.qry.type == 0              # NULL/TXT record (DNS tunneling indicator)

# TLS/C2 triage
tls.handshake.type == 1        # ClientHello — SNA / SNI info
tls.handshake.type == 2        # ServerHello — cipher suite
tls.handshake.extensions_server_name contains "xyz"

# SMB2 / lateral movement
smb2.cmd == 0x05               # SMB Write
smb2.filename contains ".exe"
dcerpc.opnum == 38             # DCOM/RPC call

# Beaconing di classifier family; interval serupa
tcp.flags.syn == 1 && dst.ip == <suspect-ip>
```

## Tips

1. Akhirnya: filter tulis manual, bukan copy-paste — kadra peril akses ke card hosts.
2. Untuk aspek waktu, gunakan `Expert Information` (Analyze menu) untuk melihat anomaly.
3. Export objects: File → Export Objects → HTTP/SMB; mengekstrak file dari PCAP langsung.

## References / Referensi

1. Wireshark Display Filter Reference — https://www.wireshark.org/docs/dfref/
2. Wireshark User's Guide — https://www.wireshark.org/docs/wsug_html/
3. RFC 3227 — Guidelines for Evidence Collection and Archiving — https://www.rfc-editor.org/rfc/rfc3227

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
