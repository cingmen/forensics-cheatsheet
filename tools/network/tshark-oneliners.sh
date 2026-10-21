#!/usr/bin/env bash
# tshark-oneliners.sh — Network forensics commands
# Repository: cingmen/forensics-cheatsheet
# License: CC-BY-4.0
# Reference: tshark(1) man page, Wireshark Display Filter docs

set -euo pipefail

# Prereq: apt install tshark
# Usage: export PCAP=/path/to/capture.pcap
# Tip: sesuaikan display filter per kasus; daftar lengkap ada di
# wireshark-display-filters.md se-folder.

# === BASIC PCAP INFO ===
tshark -r "$PCAP" -q -z io,stat
tshark -r "$PCAP" -q -z conv,tcp
tshark -r "$PCAP" -q -z io,phs        # protocol hierarchy

# === FILTER HTTP TRAFFIC ===
tshark -r "$PCAP" -Y "http" -T fields -e http.host -e http.request.uri
tshark -r "$PCAP" -Y "http.request.method == POST" \
       -T fields -e http.host -e http.request.uri -e http.file_data

# === DNS ANALYSIS ===
tshark -r "$PCAP" -Y "dns" -T fields -e dns.qry.name | sort | uniq -c | sort -rn
tshark -r "$PCAP" -Y "dns.flags.response == 1 && dns.flags.rcode != 0"

# === BEACONING DETECTION (heuristic) ===
tshark -r "$PCAP" -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0" \
       -T fields -e ip.dst | sort | uniq -c | sort -rn | head

# === EXTRACT FILES FROM PCAP ===
tshark -r "$PCAP" --export-objects http,/tmp/extracted-http/
tshark -r "$PCAP" --export-objects smb,/tmp/extracted-smb/

# === TLS ANALYSIS ===
tshark -r "$PCAP" -Y "tls.handshake.type == 1" -T fields -e tls.handshake.extensions_server_name
tshark -r "$PCAP" -Y "tls.handshake.type == 2" -T fields -e ip.src -e tls.handshake.ciphersuite

# === LATERAL MOVEMENT INDICATORS ===
tshark -r "$PCAP" -Y "smb2.cmd == 0x05" -T fields -e ip.src -e ip.dst -e smb2.filename  # SMB Write
tshark -r "$PCAP" -Y "dcerpc.opnum == 38" -T fields -e ip.src -e ip.dst                 # DCOM/RPC

# === TIMELINE EXTRACTION ===
tshark -r "$PCAP" -T fields -e frame.time -e ip.src -e ip.dst -e _ws.col.Protocol -e _ws.col.Info

# === TAKEAWAYS ===
# 1. io,stat / conv,tcp untuk potret umum, lanjut filter spesifik
# 2. Beaconing dilihat dari pola SYN berulang ke satu dst dengan interval serupa
# 3. Export-objects mengekstrak file yang ditransfer via HTTP/SMB
