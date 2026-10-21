# Digital Forensic Investigation Report / Laporan Investigasi Forensik Digital

## Document Control / Kontrol Dokumen

| Field | Value |
|---|---|
| Report ID | RPT-[YYYY]-[NNN] |
| Case Number | CASE-[YYYY]-[NNN] |
| Version | v1.0 |
| Classification | [Confidential / Restricted / Public] |
| Prepared By | [Nama, Sertifikasi, Tanda Tangan] |
| Reviewed By | [Nama, Tanda Tangan] |
| Date Issued | YYYY-MM-DD |

## 1. Executive Summary / Ringkasan Eksekutif

[Ringkasan 1-3 paragraf untuk stakeholder non-teknis. Sertakan: jenis insiden, dampak awal, kesimpulan investigasi.]

## 2. Investigation Scope / Lingkup Investigasi

[Apa yang di-investigasi, batas-batasnya, dan apa yang TIDAK termasuk.]

## 3. Methodology / Metodologi

[Standar yang dipakai, mis. NIST SP 800-86, ISO 27037, RFC 3227. Tool yang digunakan, versinya, dan validasinya.]

## 4. Evidence Examined / Bukti yang Diperiksa

| Evidence ID | Description | Hash (SHA256) | Acquisition Date | Acquired By |
|---|---|---|---|---|
| EV-[NNN] | [Deskripsi] | [64-char hex] | YYYY-MM-DD | [Nama] |

## 5. Findings / Temuan

### Finding 1: [Title]
- **Severity**: [Critical / High / Medium / Low / Info]
- **Description**: [Detail temuan]
- **Evidence**: [Link ke section bukti di appendix]
- **Timestamps**: [Waktu kejadian, dengan timezone]

[Repeat for each finding]

## 6. Analysis / Analisis

[Penjelasan korelasi antar finding, timeline, dan interpretasi.]

## 7. Conclusion / Kesimpulan

[Kesimpulan berdasarkan bukti. Hindari spekulasi.]

## 8. Limitations / Keterbatasan

[Apa yang TIDAK bisa ditentukan dari bukti, gap dalam investigasi.]

## 9. Recommendations / Rekomendasi

[Tindakan lanjutan: mitigasi, hardening, follow-up investigation.]

## Appendix A: Tool Inventory / Inventaris Tool

| Tool | Version | Purpose | Binary Hash (jika critical) |
|---|---|---|---|
| [Nama] | vX.Y.Z | [Deskripsi fungsi] | [hash] |

## Appendix B: Raw Output / Output Mentah

[Logs, command output, screenshot referensi.]

## Appendix C: References / Referensi

[Standar dan sumber yang dirujuk.]

---

**Report Version**: v1.0 · **License**: CC-BY-4.0 · **Repository**: cingmen/forensics-cheatsheet
