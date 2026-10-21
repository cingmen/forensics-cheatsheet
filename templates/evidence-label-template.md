# Evidence Label Template / Template Label Bukti

## Label Fisik (tempel pada kantong/box bukti)

```text
┌─────────────────────────────────────────────────┐
│  EVIDENCE / BUKTI                               │
│                                                 │
│  Evidence ID : EV-[YYYY]-[NNN]                  │
│  Case Number : CASE-[YYYY]-[NNN]                │
│                                                 │
│  Description : [Deskripsi singkat, mis.         │
│                "Kingston DT 32GB, hitam"]       │
│  Serial No.  : [SN]                             │
│                                                 │
│  Collected   : YYYY-MM-DD HH:MM TZ              │
│  Collected By: [Nama investigator]              │
│  Location    : [Lokasi pengambilan]             │
│                                                 │
│  SHA256      : [64-char hex, first 16 chars     │
│                jika label kecil]                │
│                                                 │
│  Storage     : [Locker ID / shelf posisi]       │
│  ⚠ JANGAN DIBUKA TANPA IZIN INVESTIGATOR       │
└─────────────────────────────────────────────────┘
```

## Panduan Pemakaian / Usage Notes

1. **Satu bukti = satu label.** Jangan menggabungkan dua item berbeda dalam satu kantong dengan satu label.
2. **Isi saat pengambilan**, bukan setelahnya — label adalah bagian dari chain of custody.
3. **Hash di label** boleh dipendekkan (16 karakter pertama SHA256) bila ruang terbatas; nilain full tetap tersimpan di form CoC.
4. **Label rusak/pecah**: ganti label, tuliskan "label replaced" dengan tanggal dan nama pengganti di form CoC, jangan buang label lama — masukkan ke kantong bersama bukti.
5. **Foto label** saat pengambilan; foto jadi bukti dokumentasi kondisi "as found".

---

**Form Version**: v1.0 · **Repository**: cingmen/forensics-cheatsheet · **License**: CC-BY-4.0
