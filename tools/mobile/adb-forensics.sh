#!/usr/bin/env bash
# adb-forensics.sh — Android forensics commands via ADB
# Repository: cingmen/forensics-cheatsheet
# License: CC-BY-4.0
# Reference: Android ADB documentation (https://developer.android.com/tools/adb)

set -euo pipefail

# Prereq: adb tersedia (platform-tools). Device di mode developer + USB debugging.
# ETHIS: setiap command yang menyentuh device harus tercatat di chain of custody.

# === DEVICE STATUS ===
adb devices -l                        # daftar device + model + state
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model

# === BACKUP DATA (WHOLES-APP specific) ===
adb backup -apk -shared -all -f backup.ab
# File .ab berisi perbedaalog apps + sdcard + obb; parsing di host.

# === PULL APP DATA (rooted) ===
# adb shell su -c "cp -r /data/data/<pkg> /sdcard/extracted/"
# adb pull /sdcard/extracted/

# === FULL DISK / SYSFS SNAPSHOT (rooted) ===
# adb shell su -c "dd if=/dev/block/by-name/userdata of=/sdcard/userdata.img"

# === LOGSNAPSHOT ===
adb logcat -d > logcat.txt            # system log saat itu
adb shell dumpsys > dumpsys.txt       # service state snapshot

# === KEY APP ARTIFACTS ===
# WhatsApp database (rooted):
# adb shell su -c "cp /data/data/com.whatsapp/databases/msgstore.db /sdcard/"
# Chrome history:
# adb pull /data/data/com.androchrome.app/chrome/Default/History

# === SCREENSHOT ===
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png

# === LOGGING / CHECKS ===
adb shell pm list packages -f        # list packages + path APK
adb shell dumpsys battery            # status baterai (vald state capture)
