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

## Crash Dump & Memori Virtual / Crash Dumps & Virtual Memory

Tiga file "memori di disk" sering menutup celah bila capture RAM terlambat atau tidak memungkinkan:

| File | Lokasi | Isi |
|---|---|---|
| `pagefile.sys` | `C:\` (hidden) | halaman memori yang sudah ditukar: jejak proses, kredensial, string komunikasi |
| `hiberfil.sys` | `C:\` (hidden) | snapshot RAM saat hibernasi — daftar proses, dokumen terbuka, sedikit kredensial |
| `swapfile.sys` | `C:\` (hidden) | swap khusus UWP/modern app |

Registry yang terkait: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management` (konfigurasi pagefile; value `ClearPageFileAtShutdown = 1` berarti OS berusaha mengosongkan pagefile saat mati — sulitkan analisis) dan `HKLM\SYSTEM\CurrentControlSet\Control\Power` (status hibernasi).

Crash dump dari BSOD juga memuat isi memori sepatutnya: `MEMORY.DMP` (kernel/complete dump) di `C:\Windows` dan minidump kecil di `C:\Windows\Minidump`. Tipe dump Windows: automatic, kernel, complete, dan small (minidump). Validasi file dump dengan `DumpChk -y <symbol-path> <dump-file>` bila ragu hasil analisisnya rusak atau symbol path salah.

### Panic triage tanpa RAM capture / Panic Triage Without RAM Capture

FTK Imager pada live system punya fitur yang jarang dipakai: **File → Obtain Protected Files** — bisa mengekstrak registry hive (SAM, SYSTEM, SOFTWARE, Security) dan file proteksi lain dari host yang sedang hidup tanpa menulis apa pun ke disk. Ditemani pagefile/hiberfil yang disalin manual dengan `dd`, ini cukup untuk triage cepat bila RAM capturernya gagal atau diblokir EDR.

### Strings di Pagefile & Hiberfil / Strings on Pagefile & Hibernate Files

Copy `pagefile.sys`/`hiberfil.sys` ke mesin analisis Linux, lalu:

```bash
# path yang pernah lewat memori
strings -a pagefile.sys | grep -aEo '[A-Za-z]:\\[ A-Za-z0-9._~-]{4,}' | sort -u | less
# URL yang pernah diakses
strings -a hiberfil.sys | grep -aEo '(https?|ftp)://[^" ]+' | sort -u | less
# email yang pernah lintas memori
strings -a pagefile.sys | grep -aEo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | sort -u
# pass kedua untuk string UTF-16LE (banyak string Windows tersimpan 16-bit)
strings -a -el pagefile.sys | grep -aEo '(https?|ftp)://[^" ]+' | sort -u | less
```

Temuan klasik dari sisi ini: sisa halaman aplikasi chat yang tertinggal, credential yang belum tertimpa halaman baru, dan domain C2 yang tidak pernah muncul di log. Karena Windows menyimpan banyak string UTF-16LE, jalankan juga `strings -a -el` — hasilnya sering beda dari pass ASCII.

Tool pelengkap: `BinText` (eksplorasi string biner di GUI), `MoonSols Windows Memory Toolkit` untuk mengkonversi `hiberfil.sys` ke format raw yang bisa diparse Volatility, dan Redline untuk triage proses/network dari dump dan IOC sweep.

## Volatility 2 untuk Dump Windows Lama / Legacy Volatility

Dump dari Windows XP/7 yang lebih tua kadang lebih mudah dipulihkan dengan Volatility 2 (Python 2, mudah dipelajari tapi sudah tak diperbarui):

```bash
python2 volatility -f dump.raw imageinfo        # profil yang disarankan
python2 volatility -f dump.raw kdbgscan          # alternatif profiler
python2 volatility -f dump.raw --profile=Win7SP1x64 pslist
python2 volatility -f dump.raw --profile=Win7SP1x64 pstree
python2 volatility -f dump.raw --profile=Win7SP1x64 malfind -p 1896
```

`malfind` di v2 melaporkan area memori dengan proteksi tipe PAGE_EXECUTE_READWRITE — sinyal injeksi; kombinasi dengan `pstree` untuk melihat parent/child menentukan prioritas mana yang dianalisis lebih dulu. Tetap prioritaskan Volatility 3 untuk Windows modern; v2 hanya untuk dump legacy yang tidak didukung v3.

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

## Capture Memori pada VM dan Cloud / VM & Cloud Capture

Mengambil memori mesin virtual berbeda dari host fisik. Pada hypervisor lokal, snapshot menyimpan state memori, tetapi formatnya bergantung pada platform (VMware, Hyper-V, KVM/QEMU). Beberapa format bisa dianalisis langsung, sebagian harus dikonversi terlebih dahulu. Catat nama file snapshot, versi hypervisor, dan waktu pembuatan di dokumen kasus.

Pada penyedia cloud, akses ke memori instance biasanya tidak langsung tersedia. Beberapa penyedia menyediakan fitur crash dump atau live memory acquisition lewat agent; sebagian lain hanya menyediakan disk snapshot dan log. Jika memori tidak dapat diambil, dokumentasikan keterbatasan itu dan andalkan artefak disk, log, dan flow jaringan sebagai pengganti.

Yang penting dalam semua skenario: verifikasi hash hasil capture, simpan di lokasi terpisah dari lingkungan produksi, dan jangan menganalisis file dump di mesin yang memiliki akses jaringan luas tanpa isolasi.

## References / Referensi

1. Volatility 3 Documentation — https://volatility3.readthedocs.io/
2. Art of Memory Forensics (public book reference) — https://www.wiley.com/en-us/The+Art+of+Memory+Forensics%3A+Detecting+Malware+and+Threats+in+Windows%2C+Linux%2C+and+Mac+Memory-p-9781118825099
3. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
