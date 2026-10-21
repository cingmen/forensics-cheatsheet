# Volatile Order Cheatsheet / Cheatsheet Urutan Volatilitas

> **TL;DR**: Order of volatility dari RFC 3227 menentukan data apa yang harus ditangkap lebih dulu saat insiden: yang paling mudah hilang (memori, cache) ditangkap sebelum disk dan backup — referensi tabel lengkap di `references/volatile-order-table.md`.

## Overview / Gambaran Umum

Ketika investigator sampai di host yang sedang hidup, waktunya berlomba dengan sistem itu sendiri: setiap detik, proses menulis file baru, isi memori berubah, dan cache diperbarui. Pada saat daya diputus, lapisan paling volatile hilang bahkan sebelum investigator tiba. Order of volatility — diambil dari RFC 3227 — memberikan urutan penangkapan: register dan cache, memori, tabel routing/ARP/proses, file sementara, disk, log remote, konfigurasi fisik, hingga arsip (backup).

Kesalahan yang paling mahal adalah urutan yang terbalik: banyak analyst datang terfokus pada disk — padahal memori, tabel proses, koneksi, dan cache adalah data yang paling rentan dan sering paling informatif. Ini juga keputusan yang berdampak strategis: data memori bisa memuat encryption key, injected code, koneksi C2 aktif, dan credential yang tidak pernah ditulis di disk.

Cheatsheet ini dipakai saat insiden yang melibatkan host hidup. Tabel referensi cepat di `references/volatile-order-table.md` menyimpulan urutan RFC 3227 dengan command capture per layer (Windows dan Linux) — gunakan sebagai checklist saat lapangan agar tidak ada lapisan yang terlewat.

## Key Concepts / Konsep Kunci

### Volatilitas / Volatility

Volatilitas menggambarkan seberapa cepat data hilang saat daya dihapus atau sistem di-reboot. Lapisan paling volatile adalah CPU register dan cache; yang paling stabil adalah arsip di media simpenan. Investigator mengumpulkan dari yang paling volatile dulu — karena data tersebut akan hilang lebih cepat dari kemampuan melakukan analisis.

### Live Acquisition / Akuisisi Host Aktif

Live acquisition adalah menangkap data saat host berjalan. Trade-off-nya sudah jelas dan harus didokumentasikan: menjalankan tool capture memakai memori, menulis log, dan mengubah host sedikit. Bila insiden berpotensi berakhir di forum formal, laporan menjelaskan tool, versinya, tanggal-waktu capture, dan hash hasil capture.

### Time Synchronization / Sinkronisasi Waktu

Waktu berurutan kejadian hanya masuk akal bila timestamp antar sumber bisa dibandingkan. Semua capture dicatat dalam UTC; bila host memakai zona berbeda, catat offset-nya. Ketidaksesuaian timezone adalah salah satu penyetelan investigasi timeline yang paling sering menimbulkan perdebatan.

## Commands / Perintah

### Windows — per Layer

```powershell
# Layer 2: capture memory (paling penting, jalankan LANGSUNG)
winpmem.exe -o C:\evidence\memdump.raw
# atau: FTK Imager → Capture Memory

# Layer 3: state sistem
route print > route.txt
arp -a > arp.txt
tasklist /v > tasklist.txt
netstat -ano > netstat.txt
ipconfig /all > ipconfig.txt

# Layer 4: temporary files
# salin %TEMP% dan pagefile (pagefile bisa memuat data memori lama)

# Layer 5: disk
dcfldd if=\\.\PhysicalDrive0 of=E:\evidence.dd bs=4M conv=sync,noerror
```

### Linux — per Layer

```bash
# Layer 2: capture memory
avml memdump.raw
# atau modul LiME

# Layer 3: state sistem
ip r > route.txt
ip n > arp.txt
ps auxf > ps.txt
ss -tulnp > sockets.txt

# Layer 4: temporary
cp -r /tmp evidence_tmp/

# Layer 5: disk
dd if=/dev/sdX of=/evidence-disk.dd bs=4M conv=sync,noerror
```

## Workflow / Alur Kerja

1. **Stop perubahan sebesar mungkin** — isolasi host dari jaringan; jangan shutdown, jangan reboot.
2. **Dokumentasi awal** — foto, catat waktu UTC, catat siapa yang melakukan apa.
3. **Capture memory** — sebelum semua tindakan lain; simpan hashnya.
4. **Capture state sistem** — proses, koneksi, cache, tabel routing.
5. **Capture temporary / volatile files** — file temp, log aktif.
6. **Lakukan disk acquisition** — dengan write blocker / read-only.
7. **Dokumentasi setiap langkah** — tool, versi, waktu, hash, di chain of custody.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Menyentuh disk sebelum memori terselamatkan** — disk relatif stabil; memori hilang. Selalu memori dulu.
- ⚠️ **Shutdown untuk 'mempercepat'** — menghapus lapisan 1–4. Isolasi jaringan saja sudah cukup.
- ⚠️ **Tidak mencatat timestamp UTC** — timeline jadi tidak bisa dibandingkan antar sumber log.
- ⚠️ **Tool capture tanpa catatan versi** — hasil tool bisa berbeda antar versi; laporan tanpa versi membingungkan reviewer.
- ⚠️ **Tidak membuat hash dari hasil capture** — integritas hasil tidak bisa dibukti.

## Cross-references / Referensi Silang

- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — disk acquisition setelah memori terselamatkan.
- [05 Memory Forensics](../cheatsheets/05-memory-forensics.md) — analisis hasil memory dump.
- `references/volatile-order-table.md` — tabel referensi cepat.
- [00 Methodology](../cheatsheets/00-methodology.md) — posisi volatile order di kerangka DFIR.

## References / Referensi

1. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227
2. NIST SP 800-86 §2.2 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
3. ISO/IEC 27037:2012 — https://www.iso.org/standard/44381.html

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
