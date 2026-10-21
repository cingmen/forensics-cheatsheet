# Install / Panduan Penggunaan Lokal

## Clone repositori

```bash
git clone https://github.com/cingmen/forensics-cheatsheet.git
cd forensics-cheatsheet
```

## Cara memakai konten

### Cheatsheets

Buka file `.md` di `cheatsheets/` dengan editor favorit (VS Code, Obsidian, tetap markdown). Tabel dan code block sudah siap dibaca GitHub maupun render lokal.

### Templates

```bash
# Salin form CoC ke folder kasus baru
cp templates/chain-of-custody-form.md /path/to/case-2026-014/
```

Isi placeholder `[...]` sesuai kasus; setiap form menyebut versi & lisensinya.

### Tool scripts

Script di `tools/` adalah kumpulan oneliner untuk disalin belahan satu-sama-skrip, bukan program yang dijalankan utuh. Pastikan variabel seperti `PCAP`, `MEMDUMP`, dan disk sumber sudah disesuaikan sebelum menyalin ke terminal Anda.

```bash
chmod +x tools/network/tshark-oneliners.sh
MEMDUMP=/path/dump.dmp bash -n tools/memory/volatility3-oneliners.sh   # cek syntax
```

## Prasyarat tool (opsional, hanya bila mau menjalankan perintah)

| Tool | Fungsi | Instal |
|---|---|---|
| `vol` (volatility3) | memory analysis | `pip install volatility3` |
| `tshark` | pcap analysis | `apt install tshark` |
| `dcfldd` | disk acquisition hashing | `apt install dcfldd` |
| `ddrescue` | disk recovery | `apt install gddrescue` |
| `sleuthkit` (mmls, fls, icat) | disk forensics CLI | `apt install sleuthkit` |
| `steghide`, `binwalk`, `zsteg` | steganalisis | apt / gem / gem |

## Kontribusi lokal

```bash
# Validasi markdown sebelum PR (disarankan)
npx markdownlint-cli2 '**/*.md'

# Validasi shell
shellcheck tools/**/*.sh
```

---

**Last updated**: 2026-10-21 · **Maintained by**: @cingmen
