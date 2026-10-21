# Security Policy / Kebijakan Keamanan

## Sifat Repo Ini / About This Repository

Repo ini adalah koleksi cheatsheet referensi (markdown + shell snippets). Tidak ada kode produksi, tidak ada server, tidak ada dependency runtime yang dieksekusi otomatis. Konsep "security vulnerability" di sini berlaku ke konten, bukan ke software.

## Pelaporan Masalah / Reporting Issues

Laporkan via [GitHub Issues](https://github.com/cingmen/forensics-cheatsheet/issues) dengan label yang sesuai.

### 1. Konten berbahaya / Dangerous content

Command yang jika di-copy-paste bisa merusak sistem (mis. `dd of=` ke device tanpa warning) tapi sudah diberi peringatan eksplisit — **bukan bug**. Command berisiko tinggi **tanpa** peringatan → laporkan sebagai `bug`.

### 2. Command salah / Incorrect commands

Jika command menghasilkan data yang salah — terutama yang memicu salah interpretasi evidence (mis. timestamp yang salah dibaca) — ini prioritas tertinggi karena bisa merusak analisis kasus nyata.

### 3. Link mati / Dead links

Link referensi yang 404 → lapor via template issue `bug-report`. CI link-check akan menangkapnya juga per mingguan.

### 4. Copyright concern

Lihat [DISCLAIMER.md](DISCLAIMER.md) → **Copyright Takedown Policy**. Subjek issue: `Copyright Concern: [file name]`.

## Praktik Operasional DFIR yang Direkomendasikan / Operational Guidance

Repo ini bukan panduan legal formal, tapi ada standar yang dijalankan:

- Setiap command yang menulis ke device (`of=`, `--export`, dll) hanya dijalankan di environment terisolasi, dengan peringatan fisik di komentar
- Penggunaan tool di konten ini untuk investigasi nyata adalah tanggung jawab investigator — selalu gunakan write-blocker untuk dead-box acquisition
- Template di `templates/` adalah referensi desain, bukan form legal yang sudah direview hukum — konsultasi profesional untuk kebutuhan kasus lokal

## Versi Konten yang Didukung / Supported Content Versions

| Branch | Status | Perbaikan konten |
|---|---|---|
| `main` | ✅ Aktif | ✅ Prioritas tinggi |
| `releases/*` (tags) | ✅ Stabil | Backport on request |

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
