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

## Katalog Perintah Volatile Windows / Windows Volatile Catalog

Perintah minimum di bagian sebelumnya bisa diperluas dengan katalog berikut — pengelompokkannya mengikuti fungsi analisis: waktu & sesi, koneksi jaringan, proses, file yang terbuka, layanan & driver, riwayat perintah, dan clipboard. Semua output disimpan ke file dan di-hash agar masuk chain of custody; jalankan dari media response yang terkontrol, bukan dari hard disk target.

### Waktu & Sesi / Time & Sessions

```cmd
date /t & time /t                             :: wall clock saat response Anda
net statistics server                        :: statistik sesi + indikasi uptime
systeminfo | findstr /C:"System Boot Time"   :: waktu boot
quser                                        :: sesi logon lokal/remote (RDP)
qprocess /a                                  :: user per sesi proses
net sessions                                 :: sesi SMB dari mesin lain, idle time
:: Sysinternals opsional: psloggedon -l, LogonSessions -p
```

Perbandingan wall clock investigator vs jam host menunjukkan apakah jam sistem bisa dipercaya — penting sebelum menomori timeline.

### Jaringan Host / Host Networking

```cmd
netstat -ano          :: koneksi TCP/UDP + PID pemilik
netstat -r            :: tabel routing (setara route print)
nbtstat -c            :: cache NetBIOS name → IP, jejak host yang pernah disambung
nbtstat -n            :: nama NetBIOS yang diregistrasi lokal
nbtstat -s            :: sesi NetBIOS aktif
arp -a                :: MAC host yang pernah dikontak
ipconfig /all         :: NIC, DHCP, DNS, WINS
ipconfig /displaydns  :: jejak DNS yang di-cache
route print           :: tabel routing + persistent routes
:: Anti-sniffer: NIC promiscuous menandai tool perekam trafik di host —
:: cek dengan PromiscDetect / PromqryUI bila tersedia.
```

### Proses, Port & Driver / Processes, Ports & Drivers

```cmd
tasklist /v                :: path (pendek), status, user context, memori
tasklist /svc              :: service di dalam tiap proses (penting utk svchost)
netstat -ano | findstr :4444   :: contoh filter port mencurigakan
tasklist /FI "PID eq 1896"     :: jembatan PID → nama proses
pslist -x                  :: Sysinternals: waktu user/kernel per proses
listdlls -u                :: Sysinternals: DLL tanpa tanda tangan = kandidat injeksi
sc query | findstr RUNNING :: pembungkus layanan yang berjalan
wmic process get executablepath,processid,commandline
wmic service get name,pathname,startmode,state,processid
driverquery /v /fo list    :: daftar driver ter-load
```

Proses: PID dari `netstat -ano` dikorelasikan dengan `tasklist /FI "PID eq N"` — ini proses-to-port mapping yang jadi alat paling murah untuk melacak pemilik koneksi jahat.

### File Terbuka & Spool / Open Files & Spool

```cmd
net file                        :: file yang dibuka lewat share + id
net file <id> /close            :: menutup file & melepas lock (hanya bila kebijakan izinkan)
handle -a                       :: Sysinternals: semua handle (file, key registry, pipe)
dir /a C:\Windows\System32\spool\PRINTERS
```

File spool pekerjaan cetak `.spl`/`.shd`/`.emf` di folder PRINTERS menyimpan metadata job (user pemilik, nama dokumen, printer, stempel waktu). Job yang selesai biasanya sudah dihapus; yang gagal dibersihkan setelah printer terputus masih tersisa.

### Riwayat Perintah & Clipboard / Command History & Clipboard

```cmd
doskey /history                 :: history di jendela cmd yang sedang dibuka (per sesi)
type %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
powershell Get-Clipboard | Out-File clipboard.txt
net share                       :: resource share lokal yang aktif
net use                         :: pemetaan drive/share + kredensial
```

Perhatikan: `cls` menghapus yang terlihat, tetapi tidak menghapus buffer doskey di sesi aktif. Sementara shell PowerShell memakai `PSReadLine` yang menyimpan riwayat perintah ke file di atas — file itu cenderung bertahan meski user menutup jendela. Pakai keduanya.

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
- ⚠️ **doskey dianggap persisten** — doskey hanya per jendela cmd aktif; untuk riwayat lintas sesi gunakan file `ConsoleHost_history.txt` PowerShell dan artefak registry RunMRU.
- ⚠️ **Melewatkan cache NetBIOS** — `nbtstat -c` sering berisi host yang pernah dikontak; artefak jaringan Windows bisa bertahan lebih lama daripada lognya.

## Cross-references / Referensi Silang

- [02 Evidence Acquisition](../cheatsheets/02-evidence-acquisition.md) — disk acquisition setelah memori terselamatkan.
- [05 Memory Forensics](../cheatsheets/05-memory-forensics.md) — analisis hasil memory dump.
- `references/volatile-order-table.md` — tabel referensi cepat.
- [00 Methodology](../cheatsheets/00-methodology.md) — posisi volatile order di kerangka DFIR.

## Contoh Capture Live / Worked Example

Bayangkan sebuah server Linux diduga dipakai untuk crypto mining. Tim SOC menerima alert pada pukul 02:10 UTC. Server masih hidup dan sedang melayani trafik produksi, jadi mematikannya bukan pilihan. Berikut urutan yang dijalankan investigator, lengkap dengan alasannya.

Langkah pertama adalah mengisolasi server dari jaringan aplikasi tanpa mematikan daya. Isolasi dilakukan lewat aturan firewall di switch, bukan dengan mencabut kabel listrik. Tujuannya jelas: menghentikan komunikasi ke pool mining, tetapi tetap mempertahankan isi memori dan state kernel. Setelah isolasi, investigator mencatat waktu UTC dan memotret layar terminal yang menunjukkan proses mencurigakan.

Langkah kedua adalah capture memori. Tool `avml` dijalankan ke disk eksternal, dengan hash SHA-256 dihitung langsung setelah capture selesai. Capture memori menjadi prioritas karena proses miner berjalan di RAM; jika server di-reboot, bukti eksekusinya hilang. Investigator mencatat nama tool, versi, dan waktu mulai/selesai di form chain of custody.

Langkah ketiga adalah capture state sistem. Perintah `ps auxf`, `ss -tulnp`, `ip r`, dan `ip n` dijalankan berurutan dan outputnya disimpan sebagai file teks. Output ini memberi potret proses, koneksi, dan tabel routing pada saat insiden. Semua file diberi hash dan dicatat sebagai turunan dari EV-ID yang sama.

Langkah keempat baru menyentuh disk. Karena server adalah mesin produksi, tim memilih melakukan image pada disk data terlebih dahulu, lalu disk sistem pada jendela maintenance berikutnya. Setiap image diverifikasi hash-nya dan disimpan di evidence locker. Dengan urutan ini, investigator mendapatkan bukti memori yang paling mudah hilang lebih dulu, tanpa harus mengorbankan layanan produksi secara keseluruhan.

## Kapan Urutan Ini Berubah / When to Deviate

Order of volatility adalah panduan, bukan hukum mutlak. Ada beberapa situasi yang wajar mengubah urutan:

1. **Ancaman penyebaran aktif** — jika host sedang menyebarkan ransomware ke host lain, isolasi dan pemutusan akses menjadi prioritas sebelum capture. Dokumentasikan bahwa capture dilakukan setelah isolasi dan sebutkan risiko kehilangan data volatile.
2. **Perangkat dengan baterai lemah** — perangkat mobile atau laptop dengan baterai hampir habis bisa mati sewaktu-waktu. Dalam kondisi ini, capture memori dilakukan lebih cepat, bahkan sebelum dokumentasi foto lengkap, asalkan waktu dan kondisi dicatat.
3. **Kebijakan yurisdiksi** — di beberapa organisasi, bukti harus diambil oleh first responder bersertifikat. Jika orang tersebut belum tiba, tim menahan diri dan hanya melakukan preservasi (isolasi, dokumentasi), bukan capture.
4. **Host virtual** — untuk VM, snapshot hypervisor bisa diambil lebih dulu karena menyimpan state memori dan disk sekaligus. Setelah snapshot, capture memori dari dalam guest tetap dianjurkan bila memungkinkan.

Yang tidak boleh berubah adalah prinsip dokumentasi: apa pun urutan yang dipilih, alasannya harus tertulis. Investigator yang menyimpang dari RFC 3227 tanpa catatan akan kesulitan menjelaskan keputusannya saat laporan ditinjau.

## Checklist Lapangan / Field Checklist

- [ ] Host diisolasi dari jaringan tanpa dimatikan.
- [ ] Waktu UTC dicatat sebelum tindakan pertama.
- [ ] Kondisi fisik dan layar difoto.
- [ ] Memori dicapture dan di-hash.
- [ ] State proses, koneksi, routing, dan ARP disimpan.
- [ ] File temporary dan log aktif disalin bila relevan.
- [ ] Disk diakuisisi dengan write blocker atau mode read-only.
- [ ] Semua langkah dicatat di form chain of custody dengan EV-ID.

## Pertanyaan Umum / FAQ

**Apakah hiberfil.sys termasuk data volatile?** Hiberfil.sys adalah salinan memori yang ditulis Windows saat hibernasi. Nilainya tinggi, tetapi isinya adalah snapshot pada saat hibernasi, bukan kondisi terkini. Jika host masih hidup, capture memori langsung tetap lebih akurat; hiberfil.sys menjadi pelengkap.

**Bagaimana kalau capture memori gagal karena tool diblokir EDR?** Catat kegagalan itu sebagai temuan. Coba tool alternatif (FTK Imager, winpmem, avml) dan dokumentasikan tool mana yang berhasil. Kegagalan capture adalah informasi penting bagi pembaca laporan karena menjelaskan batas analisis.

**Apakah pagefile harus diambil?** Pagefile bisa memuat sisa halaman memori yang sudah ditukar ke disk. Nilainya lebih rendah daripada RAM aktif, tetapi bisa berguna bila capture RAM tidak memungkinkan. Ambil pagefile setelah capture memori utama selesai.

**Berapa lama proses capture memori berlangsung?** Untuk host dengan RAM 16 GB, capture biasanya berkisar 5–20 menit tergantung kecepatan disk dan tool. Jangan menghentikan proses di tengah jalan; capture yang terputus menghasilkan dump yang tidak dapat dianalisis.

**Apakah isolasi jaringan mengubah bukti?** Isolasi jaringan mengubah state koneksi (koneksi aktif bisa terputus), tetapi tidak menghapus memori. Perubahan ini wajar dan harus dicatat: waktu isolasi, metode, dan siapa yang melakukannya. Tanpa catatan, pembaca laporan bisa salah mengira koneksi C2 berhenti karena penyerang, padahal karena tindakan tim.

## Catatan Virtualisasi / Virtualization Notes

Pada host virtual, urutan volatilitas tetap berlaku, tetapi ada lapisan tambahan: state hypervisor. Jika tersedia, snapshot VM menyimpan memori dan disk sekaligus, sehingga bisa menjadi jalan pintas yang sah untuk mengamankan state. Namun snapshot bukan pengganti capture dari dalam guest — snapshot menangkap state saat itu, dan bisa memengaruhi performa host lain di cluster yang sama.

Untuk lingkungan cloud, API penyedia layanan biasanya menyediakan kemampuan snapshot volume dan, pada sebagian kasus, capture memori terbatas. Catat ID instance, ID volume, dan waktu snapshot di form chain of custody, karena bukti cloud sering bergantung pada metadata penyedia. Jika memori tidak bisa diambil, tulis jelas di laporan bahwa analisis hanya berbasis disk dan log.

Satu hal yang sering terlewat: setelah snapshot dibuat, jangan menyalakan ulang instance dari volume asli tanpa dokumentasi. Instance baru yang dibuat dari snapshot bisa menulis ke volume yang sama bila konfigurasinya salah, dan itu menghilangkan bukti asli.

## References / Referensi

1. RFC 3227 — *Guidelines for Evidence Collection and Archiving* — https://www.rfc-editor.org/rfc/rfc3227
2. NIST SP 800-86 §2.2 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf
3. ISO/IEC 27037:2012 — https://www.iso.org/standard/44381.html

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
