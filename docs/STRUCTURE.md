# Repository Structure / Struktur Repositori

## Peta Direktori / Directory Map

```text
forensics-cheatsheet/
├── cheatsheets/     # 12 cheatsheet inti (00–11)
├── tools/           # referensi per-tool: acquisition, memory, network, disk, windows, mobile
├── templates/       # form & template dokumen forensik siap pakai
├── references/      # ringkasan standar publik (NIST, ISO, RFC) + tabel volatile order
├── docs/            # dokumentasi repo (install, structure, doclocks)
├── assets/          # banner, logo, color palette (konten visual repo)
└── .github/         # CI workflows, issue templates, PR template
```

## Penjelasan Masing-masing Folder / Folder Notes

### `cheatsheets/`

Enam belas file inti dengan nomor dua digit sebagai urutan belajar:

| File | Topik |
|---|---|
| `00-methodology.md` | kerangka DFIR (NIST/ISO/RFC/PICERL) |
| `01-chain-of-custody.md` | pengelolaan bukti |
| `02-evidence-acquisition.md` | akuisisi bukti (dd/dcfldd/ddrescue) |
| `03-volatile-order.md` | urutan capture data volatile |
| `04-disk-forensics.md` | forensik disk & Sleuth Kit |
| `05-memory-forensics.md` | analisis memori (Volatility 3) |
| `06-network-forensics.md` | analisis PCAP & flow |
| `07-windows-artifacts.md` | artefak Windows & tool parsing |
| `08-linux-artifacts.md` | artefak Linux & journal |
| `09-mobile-forensics.md` | akuisisi Android/iOS |
| `10-anti-forensics.md` | deteksi teknik anti-forensik |
| `11-report-writing.md` | menulis laporan forensik |

### `tools/`

Referensi per-tool: `.sh` berisi oneliner siap pakai, `.md` berisi referensi plugin/filter/command. Semua shell scripts punya header `# Repository`, `# License`, `# Reference` di bagian atas file.

### `templates/`

Form yang bisa di-salin ke folder kasus: chain of custody, intake, report template, IR checklist, evidence label. Semua isian `[...]` perlu diisi saat dipakai.

### `references/`

Ringkasan singkat standar publik yang paling sering dirujuk di cheatsheets. File `volatile-order-table.md` menyediakan tabel referensi cepat untuk capture live.

### `.github/`

Workflows CI (`markdown-lint`, `link-check`), issue templates (`bug-report`, `content-suggestion`, `new-cheatsheet-request`), dan PR template.

## Konvensi Penamaan / Naming Conventions

- File cheatsheet: `XX-topic-name.md` (dua digit urutan, lowercase, hyphenated).
- Branch: `feature/`, `fix/`, `docs/`, `content/` prefix.
- Checklist PR otomatis due: markdown-lint, link-check, shellcheck.
