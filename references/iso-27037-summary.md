# ISO/IEC 27037 Summary / Ringkasan ISO/IEC 27037

> **TL;DR**: ISO/IEC 27037:2012 menstandarkan peran personel dan aktivitas identification, collection, acquisition, preservation bukti digital — peran First Responder jadi pusat perhatian standar ini.

## Latar Belakang / Background

ISO/IEC 27037 berjudul *Guidelines for identification, collection, acquisition and preservation of digital evidence*. Berbeda dari NIST SP 800-86 yang berfokus teknik, standar ini menekankan dua hal: (1) peran dan kompetensi personel yang memegang bukti, dan (2) aktivitas yang dilakukan sebelum analisis dimulai. Karena itu pula standar ini paling sering dirujuk untuk kasus yang berpotensi berakhir di forum legal.

## Peran Kunci / Key Roles

| Peran | Tanggung jawab |
|---|---|
| **DEFR (Designate Data Forensics Manager)** | penanggung jawab proses forensik di organisasi |
| **First Responder** | tangan pertama di lokasi bukti; mampu identifikasi, pengamanan awal, dan dokumentasi "as found" |
| **DEFR Specialist** | specialist yang melakukan collection/acquisition/preservation secara teknis |
| **Evidence Custodian** | menjaga evidence locker dan log bukti |

Standar ini menekankan bahwa setiap peran punya kompetensi minimal dan setiap senioritas memengaruhi keputusan (mis. kapan tidak boleh menyentuh powered-on device). Aturan umumnya: bila tidak punya kompetensi melakukan sesuatu, jangan lakukan — panggil specialist.

## Empat Aktivitas Inti / Core Activities

1. **Identification** — dokumen kondisi awal, mencatat waktu, foto perangkat, dan menentukan sumber data yang relevan.
2. **Collection** — mengumpulkan data dengan cara yang meminimalkan perubahan pada sumbernya.
3. **Acquisition** — membuat salinan forensik (mis. bit-stream) dengan hash verification.
4. **Preservation** — menyimpan master dengan akses terkendali sambil menjaga kemampanan reproduksi.

## Prinsip yang Ditekankan / Key Principles

- **Dokumentasi "as found"** — setiap kondisi kecil di lokasi (lampu berkedip, layar menyala) dicatat sebelum ada tindakan.
- **Single-handler** — satu orang memegang bukti pada satu waktu; handover dicatat di form CoC.
- **Zona waktu konsisten** — timestamp ditulis dengan zona waktu eksplisit; UTC adalah acuan umum investigasi.

## Konteks di Praktik / Practical Context

Di lingkungan yang tidak punya tim forensik khusus, ISO 27037 membantu menetapkan kapan SOC analyst on-call boleh melakukan capture awal: identifikasi dan pengamanan pertama dijalankan first responder yang kompeten, sementara acquisition penuh mengikuti specialist yang bertanggung jawab.

Standar ini bersinergi dengan ISO/IEC 27042 yang membahas fase analisis dan interpretasi: 27037 menjaga bukti, 27042 menafsirkan.

## References / Referensi

1. ISO/IEC 27037:2012 — https://www.iso.org/standard/44381.html
2. ISO/IEC 27042:2015 — https://www.iso.org/standard/44405.html
3. NIST SP 800-86 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
