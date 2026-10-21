# Memory Forensics Cheatsheet / Cheatsheet Forensik Memori

> **TL;DR**: Analisis memori (RAM dump) memperlihatkan apa yang tidak pernah tertulis di disk — proses hidden, injected code, koneksi C2 aktif, dan credential. Panduan Volatility 3 dari capture sampai hunt anomali.

## Overview / Gambaran Umum

Memori adalah sumber bukti yang paling singkat hidupnya dan paling sering hilang: begitu host reboot atau dimatikan, isi RAM habis. Padahal banyak hal kejahatan modern hanya jelas di memori: malware yang tidak menulis ke disk (fileless), kode yang disuntik ke proses sah, koneksi C2 yang sedang aktif, dan credential yang sudah di-inject ke svc process.

Analisis memori secara standar memakai framework Volatility 3: `vol -f memdump.dmp <plugin>`. Perintah dasar: `windows.info` untuk identifikasi OS; `windows.pslist/pstree/psscan` untuk proses; `windows.netscan` untuk koneksi; `windows.malfind` untuk deteksi injected code. Cheatsheet ini merangkum alur capture, plugin utama, tanda-tanda mencurigakan, dan pitfall-nya.

Persiapan infrastruktur yang wajar: dump bisa berukuran 4–64 GB per host; butuh disk penyimpanan cukup dan mesin analisis dengan RAM besar untuk memprosesnya. Prinsipnya sederhana — capture cepat selama host masih hidup, analisis di kerjakan di mesin forensik.

## Key Concepts / Konsep Kunci

### Process Tree & Hidden Process / Proses Tersembunyi

- `pslist` membaca daftar proses aktif dari struktur kernel Windows.
- `psscan` memeriksa pool memory untuk struktur proses — termasuk yang disembunyikan lewat DKOM (Direct Kernel Object Manipulation).
- Bandingkan: proses yang muncul di `psscan` tetapi tidak ada di `pslist` adalah indikator kuat ada proses disembunyikan.

### Malware Injection / Suntik Modul

- `malfind` memeriksa Virtual Address Descriptor (VAD) — mencari memori dengan flag RWX dan isi yang tidak tampak seperti kode sah.
- Hasil malfind yang menempel di proses sah (svchost.exe, explorer.exe, cmd.exe) adalah tanda kuat terjadi injection.
- `dlllist` dan `handles` melengkapi pemeriksaan — mencari module path yang aneh pada proses yang bersangkutan.

### Network Connections in Memory / Koneksi Jaringan di RAM

- `netscan` membaca tabel koneksi di memori: alamat IP, port, state, hingga proses pemiliknya.
- C2 biasanya terlihat sebagai koneksi TCP yang berulang ke satu IP dengan interval serupa, dari proses yang mencurigakan.

## Commands / Perintah

```bash
# Kapten: identifikasi OS dan kernel
vol -f memdump.dmp windows.info

# Baseline proses
vol -f memdump.dmp windows.pslist
vol -f memdump.dmp windows.pstree

# Bandingkan dengan scan
vol -f memdump.dmp windows.psscan

# Injected code / malware
vol -f memdump.dmp windows.malfind

# Koneksi aktif
vol -f memdump.dmp windows.netscan

# Persistence via registry (dari RAM)
vol -f memdump.dmp windows.registry.printkey --key Software\\Microsoft\\Windows\\CurrentVersion\\Run

# Extract sunk file/processes
vol -f memdump.dmp windows.dumpfiles --pid "$PID" --dump

# Timeline
vol -f memdump.dmp windows.timeliner
```

## Workflow / Alur Kerja

1. **Capture memory** — di live host (`winpmem`, FTK Imager, atau AVML untuk Linux); simpan hash & versi tool.
2. **Identifikasi OS** — `windows.info`; pastikan framework mengenali kernel yang benar.
3. **Baseline proses** — pslist + pstree; catat proses sah yang relevan & process tree.
4. **Scan tambahan** — pss untuk proses hidden; bandingkan antara pslist vs psscan.
5. **Hunt malware** — malfind per-host RWX + dlllist/handles pada proses mencurigakan; netscan untuk C2.
6. **Extract artifacts** — dumpfiles untuk memperoleh file yang dihunt; analisis sandbox offline bila perlu.
7. **Korelasi** — pasangkan temuan memori dengan artefak disk/log — satu kasus, satu timeline.

## Common Pitfalls / Kesalahan Umum

- ⚠️ **Capture terlambat** — host sudah reboot: memori hilang. Buat capture memori sebagai langkah pertama.
- ⚠️ **Salah versi tool / framework** — Volatility 3 butuh versi sesuai OS; dokumentasi resmi di-update; pastikan pip terbaru.
- ⚠️ **Mesin analisis tidak cukup RAM** — memproses dump besar butuh memori kerja; bila RAM kecil, analisis bisa gagal atau lambat.
- ⚠️ **Membaca malfind sebagai fakta serangan** — malfind adalah indikator; verifikasi dengan konteks dan parent process.
- ⚠️ **Melihat koneksi tanpa menghubungkan ke proses** — koneksi C2 perlu dikaitkan dengan proses pemiliknya, bukan dilihat terpisah.

## Cross-references / Referensi Silang

- [03 Volatile Order](../cheatsheets/03-volatile-order.md) — urutan capture memory.
- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — penyimpanan dump & hash.
- [`tools/memory/volatility3-cheatsheet.md`](../tools/memory/volatility3-cheatsheet.md) — daftar plugin lengkap.
- [07 Windows Artifacts](../cheatsheets/07-windows-artifacts.md) — artefak Windows di disk.

## Contoh Investigasi / Worked Example

Sebuah workstation Windows 11 melaporkan aktivitas aneh: antivirus mati sendiri dan muncul koneksi keluar ke IP yang tidak dikenal. Host masih hidup, jadi tim menangkap memori terlebih dahulu, lalu mematikan host dan mengambil disk image.

Langkah pertama adalah `windows.info`. Output menunjukkan versi kernel yang dikenali, sehingga plugin lain bisa dijalankan dengan benar. Langkah kedua adalah `windows.pstree` untuk melihat pohon proses. Di sana terlihat `WINWORD.EXE` memiliki anak `powershell.exe` dengan argumen `-enc` dan blob base64 — pola yang sangat tidak wajar, karena Word tidak lazim memanggil PowerShell.

Langkah ketiga adalah `windows.psscan` dan membandingkannya dengan `pslist`. Hasilnya menunjukkan dua proses tambahan yang tidak ada di `pslist`, salah satunya bernama mirip proses sistem (`svch0st.exe`, dengan angka nol). Ini indikasi proses disembunyikan lewat teknik DKOM.

Langkah keempat adalah `windows.malfind` pada PID yang mencurigakan. Hasilnya menunjukkan halaman memori dengan proteksi RWX dan header PE yang tidak utuh — khas injected payload. Investigator kemudian menjalankan `windows.dumpfiles` untuk mengekstrak payload tersebut dan mengirimkannya ke sandbox offline.

Langkah kelima adalah `windows.netscan`. Di sana terlihat koneksi TCP dari proses mencurigakan ke IP eksternal pada port 443, dengan waktu koneksi yang berulang kira-kira setiap 60 detik. Pola ini konsisten dengan beaconing C2. Langkah keenam adalah mencatat semuanya ke laporan: PID, nama proses, parent, waktu, IP tujuan, dan rujukan ke file dump.

Kesimpulan dari contoh ini: bukti terkuat datang dari kombinasi beberapa plugin. `pstree` saja tidak cukup, `malfind` saja bisa menimbulkan false positive, tetapi tiga sumber yang saling menguatkan membentuk kesimpulan yang dapat dipertanggungjawabkan.

## Integrasi dengan Artefak Disk / Cross-Source Validation

Analisis memori paling kuat ketika dikombinasikan dengan artefak disk. Beberapa pasangan yang sering dipakai:

| Temuan memori | Konfirmasi di disk |
|---|---|
| Proses aneh di `psscan` | Prefetch, Amcache, Shimcache |
| Injected code di `malfind` | File yang diekstrak, hash-nya dicocokkan dengan AV/threat intel |
| Koneksi C2 di `netscan` | Firewall log, proxy log, PCAP |
| Registry Run key dari memori | Hive di disk (SYSTEM/SOFTWARE) |
| Command line mencurigakan | Event log Sysmon (jika terpasang) |

Jika temuan memori tidak punya padanan di disk, bukan berarti temuan itu salah — bisa jadi artefak disk sudah dihapus atau log tidak menangkapnya. Tetapi ketidakcocokan harus dijelaskan di laporan, misalnya: "proses X terlihat di memori, tetapi Prefetch tidak tersedia karena fitur tersebut dimatikan pada host ini".

## Checklist Analisis Memori / Memory Analysis Checklist

- [ ] Dump memori di-hash dan dicatat di chain of custody.
- [ ] `windows.info` dijalankan untuk memastikan OS dikenali.
- [ ] `pslist` dan `pstree` dijalankan dan disimpan sebagai baseline.
- [ ] `psscan` dibandingkan dengan `pslist` untuk mencari proses tersembunyi.
- [ ] `malfind` dijalankan dan hasilnya diverifikasi, bukan langsung disimpulkan.
- [ ] `netscan` dikaitkan dengan proses pemilik koneksi.
- [ ] File hasil dump diberi hash dan dianalisis di lingkungan terpisah.
- [ ] Semua temuan dirujuk ke EV-ID di laporan.

## Pertanyaan Umum / FAQ

**Apakah Volatility 3 butuh profil?** Tidak. Berbeda dari versi 2, Volatility 3 mendeteksi simbol kernel secara otomatis. Jika simbol tidak ditemukan, tool akan mencoba mengunduhnya; pada lingkungan tanpa internet, siapkan simbol secara offline.

**Mengapa hasil `malfind` sangat banyak?** Beberapa aplikasi sah (browser, Java, .NET) memakai memori executable. Fokus pada proses yang tidak wajar, path aneh, atau kombinasi dengan indikator lain. Jangan menyimpulkan seluruh hasil sebagai malware.

**Bisakah menganalisis dump dari VM?** Bisa, selama dump diambil dari dalam guest atau snapshot memori hypervisor yang kompatibel. Perhatikan bahwa snapshot hypervisor menyertakan state perangkat virtual yang bisa memengaruhi hasil plugin.

## Simbol & Lingkungan Offline / Symbols and Offline Setup

Volatility 3 membutuhkan simbol (symbol table) untuk menerjemahkan struktur kernel. Pada lingkungan dengan internet, simbol diunduh otomatis dari server Volatility Foundation. Namun banyak laboratorium forensik beroperasi tanpa koneksi internet — justru karena alasan keamanan. Dalam kondisi ini, simbol harus disiapkan lebih dulu.

Langkahnya: unduh paket simbol untuk versi Windows yang relevan dari sumber resmi, letakkan di direktori simbol lokal, lalu jalankan Volatility dengan opsi `--symbol-dirs` yang menunjuk ke direktori tersebut. Catat versi simbol di laporan — pembaca yang mencoba mereproduksi hasil perlu tahu simbol apa yang dipakai.

Selain simbol, siapkan juga:

1. **Memori kerja yang cukup** — memproses dump 32 GB dengan mesin 8 GB akan sangat lambat atau gagal.
2. **Ruang disk** — hasil `dumpfiles` bisa membengkak; sediakan setidaknya dua kali ukuran dump.
3. **Tool pendukung** — `strings`, `yara`, dan sandbox offline untuk menganalisis file hasil ekstraksi.
4. **Isolasi jaringan** — jangan pernah membuka file hasil dump di mesin yang terhubung ke jaringan produksi tanpa pemeriksaan.

Jika simbol tidak tersedia dan tidak bisa diunduh, analisis dapat dilakukan sebagian dengan plugin yang tidak membutuhkan simbol, tetapi hasilnya terbatas dan harus dijelaskan di bagian limitations laporan.

## References / Referensi

1. Volatility 3 Documentation — https://volatility3.readthedocs.io/
2. Art of Memory Forensics (public book reference) — https://www.wiley.com/en-us/The+Art+of+Memory+Forensics%3A+Detecting+Malware+and+Threats+in+Windows%2C+Linux%2C+and+Mac+Memory-p-9781118825099
3. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
