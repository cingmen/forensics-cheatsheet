#!/usr/bin/env bash
# dcfldd-oneliners.sh — Forensic acquisition commands using dcfldd
# Repository: cingmen/forensics-cheatsheet
# License: CC-BY-4.0
# Reference: dcfldd man page, NIST CFTT project

set -euo pipefail

# === BASIC IMAGE WITH ON-THE-FLY HASHING ===
# dcfldd generate hash md5 secara window, ditulis ke hashlog
dcfldd if=/dev/sdX of=evidence.dd bs=4M conv=sync,noerror \
       hashwindow=512M hashlog=evidence.dd.md5 hash=md5,sha1

# === MULTIPLE OUTPUT (dua salinan sekaligus) ===
# dcfldd dapat menulis output ke lebih dari satu file
dcfldd if=/dev/sdX of=master.e01 bs=4M conv=sync,noerror ofsplit=4G

# === VERIFY WRITE ===
# Perbandingan hash sumber vs salinan
dcfldd if=/dev/sdX of=evidence.dd bs=4M conv=sync,noerror \
       verifylog=evidence.verify.log hash=sha256

# === SPLIT OUTPUT ===
dcfldd if=/dev/sdX of=evidence.part bs=4M conv=sync,noerror \
       ofsplit=4G hashlog=split.md5

# === VERIFY IMAGE INTEGRITY ===
md5sum -c evidence.dd.md5

# === CATATAN ===
# dcfldd adalah fork dd forensik keluaran dari DoD; alternatif official:
# dc3dd (NIST). Fungsi utama: hashing on-the-fly + progress display.
