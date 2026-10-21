#!/usr/bin/env bash
# volatility3-oneliners.sh — Common Volatility 3 commands
# Repository: cingmen/forensics-cheatsheet
# License: CC-BY-4.0
# Reference: Volatility 3 docs (https://volatility3.readthedocs.io/)

set -euo pipefail

# Prereq: pip install volatility3
# Usage: export MEMDUMP=/path/to/memory.dmp
PID=4796   # ganti dengan PID yang relevan

# === IDENTIFY IMAGE / FRAMEWORK INFO ===
vol -f "$MEMDUMP" windows.info

# === PROCESS ANALYSIS ===
vol -f "$MEMDUMP" windows.pslist
vol -f "$MEMDUMP" windows.pstree
vol -f "$MEMDUMP" windows.psscan    # Detect hidden processes
vol -f "$MEMDUMP" windows.cmdline   # Process command lines

# === NETWORK CONNECTIONS ===
vol -f "$MEMDUMP" windows.netscan

# === MALWARE DETECTION ===
vol -f "$MEMDUMP" windows.malfind   # Find injected code (RWX pages)
vol -f "$MEMDUMP" windows.dlllist   # List DLLs per process
vol -f "$MEMDUMP" windows.handles   # Handles per process

# === REGISTRY (from memory) ===
vol -f "$MEMDUMP" windows.registry.hivelist
vol -f "$MEMDUMP" windows.registry.printkey --key "Software\\Microsoft\\Windows\\CurrentVersion\\Run"

# === FILE EXTRACTION ===
vol -f "$MEMDUMP" windows.dumpfiles --pid "$PID" --dump
vol -f "$MEMDUMP" windows.memmap --pid "$PID" --dump

# === USER ARTIFACTS ===
vol -f "$MEMDUMP" windows.clipboard            # Clipboard contents
# vol -f "$MEMDUMP" windows.getsids --pid "$PID"   # SIDs user (runit jika perlu)
vol -f "$MEMDUMP" windows.shimcache            # Program execution evidence

# === TIMELINE ===
vol -f "$MEMDUMP" windows.timeliner

# === SUSPICIOUS INDICATORS ===
# 1. Compare pstree vs psscan → hidden (unlinked) processes
# 2. malfind results → injected code (look for RWX memory pages)
# 3. netscan → unknown IPs (correlate with threat intel)
# 4. cmdline → weird parent/child (e.g., WINWORD spawning cmd.exe)
