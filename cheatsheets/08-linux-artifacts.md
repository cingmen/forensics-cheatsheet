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

## Studi Kasus: SSH Brute Force / Worked Example

Sebuah server web melaporkan lonjakan beban CPU dan koneksi keluar yang tidak dikenal. Tim mencurigai server sudah diambil alih. Analisis dimulai dari artefak Linux yang tersedia.

Langkah pertama adalah memeriksa login gagal dan berhasil. `lastb -F` menunjukkan ribuan percobaan gagal dari beberapa IP dalam rentang satu jam, sedangkan `last -F` menunjukkan satu login sukses dari IP yang sama tak lama setelahnya. Ini pola khas brute force yang berhasil.

Langkah kedua adalah memeriksa `auth.log` (atau `secure` di RHEL) untuk melihat akun yang dipakai dan jam login. Perhatikan juga apakah ada pembuatan user baru (`useradd`) atau perubahan sudoers. Langkah ketiga adalah memeriksa `~/.bash_history` untuk akun tersebut. Jika history kosong, periksa `.zsh_history`, `.viminfo`, dan `.python_history` sebagai alternatif.

Langkah keempat adalah memeriksa persistence. Cron dan systemd timer sering dipakai untuk menjalankan payload berulang. Periksa `/etc/cron*`, `/var/spool/cron/*`, dan `systemctl list-timers --all`. Periksa juga `~/.ssh/authorized_keys` untuk key yang tidak dikenal, serta service baru di `/etc/systemd/system/`.

Langkah kelima adalah memeriksa auditd bila aktif. `ausearch` bisa menunjukkan eksekusi perintah dan akses file yang mencurigakan. Jika auditd tidak aktif, gunakan log aplikasi dan timeline filesystem sebagai pengganti. Terakhir, korelasikan dengan trafik jaringan: koneksi keluar ke IP asing pada jam yang sama dengan login sukses memperkuat kesimpulan.

## Persistence Linux yang Sering Terlewat / Overlooked Persistence

Sebagian besar investigator memeriksa cron dan `~/.ssh/authorized_keys`, lalu berhenti. Padahal ada beberapa lokasi lain yang sering dipakai:

| Lokasi | Cara kerja |
|---|---|
| `/etc/ld.so.preload` | Memuat library sebelum program lain; sering dipakai rootkit |
| `/etc/profile.d/*.sh` | Dijalankan setiap login shell |
| `~/.bashrc`, `~/.profile` | Perintah dijalankan saat shell interaktif dibuka |
| `/etc/systemd/system/*.service` | Service baru bisa berjalan saat boot |
| `systemd user units` | Unit per user di `~/.config/systemd/user/` |
| `/etc/rc.local` | Skrip boot klasik, masih ada di beberapa distro |
| `pam.d` modifications | Modifikasi PAM bisa menangkap kredensial |

Periksa juga waktu modifikasi file-file ini. File konfigurasi sistem yang berubah pada hari insiden adalah petunjuk kuat. Gunakan `find /etc -mtime -7 -type f` untuk melihat perubahan seminggu terakhir, lalu bandingkan dengan timeline login.

## Checklist Artefak Linux / Linux Artifact Checklist

- [ ] `last`, `lastb`, dan `who` diperiksa untuk login history.
- [ ] `auth.log`/`secure` dibaca, termasuk file rotasi.
- [ ] Shell history semua user dan shell diperiksa.
- [ ] Cron, systemd timers, dan service baru diperiksa.
- [ ] `authorized_keys` dan konfigurasi SSH diperiksa.
- [ ] auditd diperiksa bila aktif.
- [ ] File konfigurasi yang berubah dalam 7 hari terakhir dicari.
- [ ] Timestamp dinormalisasi ke UTC dan dirujuk ke EV-ID.

## Pertanyaan Umum / FAQ

**Bagaimana jika log sudah dihapus?** Periksa log rotasi (`.1`, `.gz`, `.xz`), journal persisten, dan SIEM. Jika semuanya hilang, gunakan timeline filesystem dan artefak lain sebagai bukti tidak langsung.

**Apakah `history` bisa dipercaya?** Tidak sepenuhnya. History bisa dihapus, dimanipulasi, atau tidak tercatat karena `HISTFILE` dimatikan. Gunakan sebagai petunjuk, bukan bukti tunggal.

**Mengapa auditd penting?** Auditd mencatat syscall dan akses file pada level kernel, sehingga lebih sulit dihindari dibanding log aplikasi. Namun auditd harus diaktifkan sebelum insiden; tidak bisa diaktifkan setelahnya untuk mendapatkan data lampau.

## Koleksi Log yang Aman / Safe Log Collection

Saat host masih hidup, kumpulkan log sebanyak mungkin tanpa mengubah sistem. Prioritas pertama adalah log yang cepat terrotasi: `auth.log`, `syslog`, dan journal. Gunakan media eksternal yang sudah di-hash dan dicatat di chain of custody.

```bash
# Buat direktori tujuan di media eksternal
mkdir -p /mnt/evidence/logs

# Salin log dengan metadata dipertahankan
cp -a /var/log/* /mnt/evidence/logs/

# Simpan state runtime yang tidak tersedia di disk
journalctl --no-pager > /mnt/evidence/logs/journal-full.txt
ps auxf > /mnt/evidence/logs/ps.txt
ss -tulnp > /mnt/evidence/logs/sockets.txt

# Hash seluruh koleksi
cd /mnt/evidence && find logs -type f -print0 | sort -z | xargs -0 sha256sum > logs.sha256
```

Hindari perintah yang menulis ke filesystem host, seperti `last -w` yang bisa memperbarui `wtmp` pada beberapa implementasi. Jika ragu, salin file mentah dan analisis di mesin lain.

Setelah koleksi selesai, buat catatan waktu UTC dan daftar file yang diambil. Simpan juga versi tool yang dipakai (`journalctl --version`, `uname -a`) karena perilaku log bisa berbeda antar versi sistem.

## Container dan Artefak Docker / Container Artifacts

Banyak layanan Linux modern berjalan di container. Untuk insiden pada container, artefak host saja tidak cukup: perlu juga data dari Docker/containerd dan image container itu sendiri.

Lokasi yang perlu diperiksa di host:

1. `/var/lib/docker/containers/<id>/` — log container dan konfigurasi.
2. `/var/lib/docker/overlay2/` — layer filesystem container; perubahan di layer atas menyimpan file yang ditulis saat runtime.
3. `docker inspect <container>` — metadata container, termasuk mount dan environment.
4. `docker logs <container>` — stdout/stderr container yang sering memuat error dan jejak serangan.

Untuk image, simpan `docker save` hasil ekspor atau hash image ID. Jika container sudah dihentikan, hindari menghapusnya — hentikan container lain yang tidak relevan, tetapi jangan `docker rm` sebelum bukti diambil. Dokumentasikan versi Docker/containerd, karena layout direktori bisa berbeda antar versi.

## References / Referensi

1. rsyslog Documentation — https://www.rsyslog.com/doc/
2. systemd journal documentation — https://www.freedesktop.org/software/systemd/man/journalctl.html
3. Linux audit — https://github.com/torvalds/linux/tree/master/ Documentation/audit + man pages `ausearch(8)`
4. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
