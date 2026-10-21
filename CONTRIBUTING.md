# Contributing / Panduan Kontribusi

Terima kasih sudah mau berkontribusi ke `forensics-cheatsheet`! Panduan ini menjelaskan cara berkontribusi dengan benar, mulai dari jenis kontribusi yang diterima, aturan penulisan konten, sampai proses review. Semua kontribusi tunduk pada [Code of Conduct](CODE_OF_CONDUCT.md) — baca dulu sebelum mulai.

## Bentuk Kontribusi yang Diterima / Accepted Contributions

| Jenis | Contoh | Diprioritaskan? |
|---|---|---|
| Fix typo / perbaikan kalimat | Salah ketik di cheatsheet | ✅ High |
| Tambah command example | Oneliner tshark baru di `tools/` | ✅ High |
| Tambah referensi publik | Sumber NIST/ISO/RFC di References | ✅ High |
| Perbaikan teknis command | Flag salah / output beda dari tool versi baru | ✅ High |
| Cheatsheet baru | Topik yang belum ter-cover di `cheatsheets/` | 🔶 Discuss dulu via issue |
| Terjemahan Inggris | Branch `i18n-en` — parallel structure | 🔶 Koordinasi dulu |
| Diagram original | Mermaid/Excalidraw buatan sendiri | ✅ High |

## Aturan Wajib Konten / Hard Content Rules

1. **100% sumber publik.** Tidak ada materi dari courseware berbayar apapun (EC-Council, SANS/GIAC, (ISC)², CompTIA, dll). Konten harus bisa di-derive dari sumber publik.
2. **Minimal 3 referensi publik per cheatsheet**, dengan prioritas: standar internasional → RFC → tool documentation → buku publik → blog authoritatif.
3. **Original wording.** Paraphrase dengan bahasa sendiri — tanpa copy-paste verbatim, termasuk ke sumber publik.
4. **Bahasa**: judul bilingual (English / Indonesia), isi Bahasa Indonesia, command tetap English.
5. **Tanpa exam dumps.** Konten apapun dari pertanyaan ujian / NDA langsung ditolak.

## Struktur File yang Diharapkan / Expected File Layout

```
cheatsheets/       → XX-topic-name.md (2-digit + topic, lowercase, hyphenated)
tools/<category>/  → oneliner .sh / reference .md per tool
templates/         → form & doc template siap pakai
references/        → summary standar publik (NIST, ISO, RFC)
```

Setiap cheatsheet ikuti struktur standar:
`TL;DR → Overview → Key Concepts → Commands → Workflow → Common Pitfalls → Cross-references → References`.

## Alur Kerja GitHub / GitHub Workflow

1. **Fork & branch**: pakai prefix `feature/`, `fix/`, `docs/`, atau `content/` (mis. `content/windows-artifacts-srum`).
2. **Commit atomik**: satu topik per commit, message deskriptif.
3. **PR**: link issue-nya (kalau ada), jelaskan apa yang berubah dan kenapa.
4. **CI harus pass**: `markdown-lint`, `link-check`. CI fail → PR tidak direview.

## Checklist Sebelum Submit PR / Pre-submit Checklist

- [ ] Command sudah dites di tool versi terkini (atau tandai versi yang dipakai)
- [ ] Tidak ada konten dari courseware / exam dumps / NDA
- [ ] Minimal 3 referensi publik (untuk cheatsheet baru)
- [ ] Link internal repo masih valid (tidak ada 404)
- [ ] Markdown lolos `markdownlint-cli2` (auto-run di CI)
- [ ] Shell scripts lolos `shellcheck` (auto-run di CI)

## Review & Merge

- CI pass → PR direview maintainer (biasanya ≤72 jam)
- Perbaikan minor di-merge langsung
- Cheatsheet baru didiskusikan dulu via issue `new-cheatsheet-request`

## Pertanyaan?

Buka [issue](https://github.com/cingmen/forensics-cheatsheet/issues) dengan template yang sesuai. Pertanyaan teknis (non-CoC) juga diterima sebagai `content-suggestion`.

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
