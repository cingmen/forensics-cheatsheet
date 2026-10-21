#!/usr/bin/env bash
# dd-commands.sh — Forensic acquisition commands using dd
# Repository: cingmen/forensics-cheatsheet
# License: CC-BY-4.0
# Reference: dd(1) man page, NIST SP 800-86 §3

set -euo pipefail

# === BASIC FORENSIC IMAGE ===
# Create raw image with conv flags (recommended for forensics)
dd if=/dev/sdX of=evidence.dd bs=4M conv=sync,noerror status=progress

# === HASH THE IMAGE (MD5 + SHA256) ===
md5sum evidence.dd > evidence.dd.md5
sha256sum evidence.dd > evidence.dd.sha256

# === SPLIT IMAGE (untuk evidence besar) ===
# Split raw output jadi 4GB chunks dd | split
dd if=/dev/sdX bs=4M conv=sync,noerror status=progress | split -b 4G - evidence.split.

# === CATATAN BAD SECTOR ===
# dcbu dengaan dibandingkan: dd tidak mengendalikan recovery sektor error.
# Untuk disk bermasalah gunakan dcfldd atau ddrescue (lihat script lain).

# === SPLIT HASH ===
# Untuk split image, hash per chunk:
# md5sum evidence.split.* > evidence.split.md5

# === VERIFY IMAGE INTEGRITY ===
md5sum -c evidence.dd.md5
sha256sum -c evidence.dd.sha256

# === WRITE TO DEVICE (RESTORE) ===
# DANGER: periksa target device dua kali sebelum menjalankan!
# dd if=evidence.dd of=/dev/sdY bs=4M status=progress

# === MOUNT IMAGE READ-ONLY ===
# Linux:
# losetup --find --partscan --read-only evidence.dd
# mount -o ro /dev/loop0p1 /mnt/evidence

# === CONVERT IMAGE FORMAT ===
# Raw to EWF (EnCase Evidence File) — requires ewfacquire
# ewfacquire evidence.dd
