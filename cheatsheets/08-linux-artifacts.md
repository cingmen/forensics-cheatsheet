# Linux Artifacts Cheatsheet / Cheatsheet Artefak Linux

> **TL;DR**: Lokasi artefak Linux yang paling sering diperiksa — /var/log, ~/.bash_history, cron, systemd journal, auditd — dengan command `journalctl`, `ausearch`, `last`, dan alur timeline.

## Overview / Gambaran Umum

Sistem Linux menulis jejaknya di tempat yang tersebar: log tradisional di `/var/log`, shell history di home directory tiap user, kerja terjadwal di cron, dan event terstruktur di systemd journal. Investigator Linux yang baik tahu ke mana melihat dan bagaimana menautkan sumber-sumber itu ke satu timeline.

Distribusi bisa mengubah detail: Debian/Ubuntu memakai `auth.log`, RHEL/Fedora memakai `secure`; journalized systemd sejak Ubuntu 16.04 menyatukan banyak log ke binary journal. Macam log dari berbagai daemon (sshd, sudo, cron) kadang tersebar di beberapa file sekaligus — pastikan untuk memeriksa keduanya.

Praktik penting saat investigasi: jangan menulis apa pun ke host yang sedang dianalisis. Kerjakan di salinan yang di-mount read-only; bila host masih hidup, ambil snapshot atau salin log secepatnya sebelum rotasi membuang entri.

## Key Concepts / Konsep Kunci

### Login & Session / Login dan Sesi

- **`/var/log/auth.log` (Debian) atau `/var/log/secure` (RHEL)** — SSH login, sudo, su, sukses dan gagal.
- **`last`** membaca `wtmp` (riwayat login), `lastb` membaca `btmp` (login gagal), `who` membaca `utmp` (sesi aktif).
- **systemd journal** — `journalctl` dengan filter unit, waktu, dan user; journal bisa persist di `/var/log/journal` atau hanya runtime (hilang saat reboot).

### Shell History / Riwayat Shell

- `~/.bash_history` (dan `~/.zsh_history` untuk zsh) menyimpan perintah per user — namun mudah dihapus dan tidak menandai waktu secara default (perm `HISTTIMEFORMAT`).
- **`~/.viminfo`, `~/.mysql_history`, `~/.python_history`** — riwayat tool lain; sering memuat informasi yang tidak ada di bash history.
- **`~/.ssh/known_hosts` & `~/.ssh/authorized_keys`** — host yang pernah dihubungi dan key yang terpasang; berguna untuk melacak gerak lateral dari host ini.

### Scheduled Tasks & Services / Kerja Terjadwal & Service

- `/etc/cron*` dan `/var/spool/cron/*` — cron per user dan sistem.
- **systemd timers** — `systemctl list-timers --all`; unit-nya di `/etc/systemd/system/` dan `usr/lib/systemd/system/`.
- **rc.local, /etc/rc.d, /etc/init.d** — skrip boot yang sudah langka tapi masih ada di beberapa distribusi.

### Log & Accounting / Akuntansi

- **auditd** — log audit kernel yang detail (dengan rule): `ausearch` untuk mencari per event; `aureport` untuk ringkasan.
- **`/var/log/syslog`** — log sistem umum; kernel log via `dmesg`; log package manager (`dpkg.log`, `dnf.log`) menunjukkan kapan software/patch terpasang.

## Commands / Perintah

```bash
# === Login history ===
last -F                   # login history dengan timestamp penuh
lastb -F                  # login gagal (butuh akses ke /var/log/btmp)
who -a                    # sesi aktif

# === Journal ===
journalctl --since "2026-10-20 09:00" --until "2026-10-20 17:00"
journalctl -u ssh --since today
journalctl --disk-usage                # ukuran journal di disk

# === Shell history (per user) ===
cat /home/<user>/.bash_history
cat /home/<user>/.zsh_history | less

# === auditd ===
ausearch -k <key-name> --start 10/20/2026 09:00:00
aureport --auth                       # ringkasan login
aureport --file                       # ringkasan akses file

# === Cron & systemd ===
cat /etc/crontab; ls /etc/cron.d/
systemctl list-timers --all
ls -la /etc/systemd/system/ /usr/lib/systemd/system/

# === Persistence check umum ===
ls -la /etc/rc.local /etc/init.d/ 2>/dev/null
cat /root/.ssh/authorized_keys
```

## Workflow / Alur Kerja

1. **Verifikasi & salin** — kerja di salinan; hindari menulis ke host yang hidup (mount read-only, journalctl read-only).
2. **Login timeline** — `last`/`lastb` + auth/secure log; tandai login anomali (IP asing, jam ganjil).
3. **Shell history** — gabungkan history per user; cek `.viminfo`/history Python yang menyaingi.
4. **Persistence** — cron, systemd timers, services, rc scripts, authorized_keys — cari yang tidak wajar.
5. **auditd** — bila aktif, gunakan sebagai sumber presisi; aureport untuk latar umum.
6. **Timeline & korelasi** — gabungkan dengan log dan artefak dari host lain; dokumentasikan setiap temuan dengan EV-ID.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Log terrotasi** — logrotate memutar file; jangan berhenti pada file aktif saja — cek juga `auth.log.1`, `*.gz`, `*.xz` untuk riwayat lebih panjang.
- ⚠️ **bash history bisa dihapus** — user bisa menjalankan `unset HISTFILE` atau menghapus file; ketiadaan history bukan bukti tidak ada aktivitas.
- ⚠️ **`.zsh_history` sering terlewat** — bila host memakai zsh, periksa kedua file history.
- ⚠️ **Journal runtime-only** — systemd journal bisa tersimpan hanya di memori; final disimpan di `/var/log/journal`; log lain bisa jatuh di file yang terrotasi.
- ⚠️ **auditd tidak aktif** — banyak host tidak mengaktifkan auditd secara default; bila tidak aktif, jangan mengasumsikan detail tersedia.

## Cross-references / Referensi Silang

- [04 Disk Forensics](../cheatsheets/04-disk-forensics.md) — parsing disk ext4.
- [03 Volatile Order](../cheatsheets/03-volatile-order.md) — capture state Linux aktif.
- [10 Anti-Forensics](../cheatsheets/10-anti-forensics.md) — log-tampering di Linux.

## References / Referensi

1. rsyslog Documentation — https://www.rsyslog.com/doc/
2. systemd journal documentation — https://www.freedesktop.org/software/systemd/man/journalctl.html
3. Linux audit — https://github.com/torvalds/linux/tree/master/ Documentation/audit + man pages `ausearch(8)`
4. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
