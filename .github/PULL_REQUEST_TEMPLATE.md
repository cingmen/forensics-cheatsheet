<!-- PR yang baik menyebut issue terkait, menjelaskan apa yang berubah dan kenapa, serta lulus CI (markdown-lint & link-check). -->

## Apa yang berubah?

<!-- Ringkas perubahan: konten baru / fix typo / fix command / illustration -->

## Kenapa perlu diubah?

<!-- Konteks: bug yang diperbaiki, topik yang hilang, artefak yang lebih jelas -->

## Terkait dengan issue

<!-- Link issue terkait (bug report / content suggestion / new cheatsheet request), mis.:

Closes #12

-->

## Checklist PR

- [ ] Konten tidak menyalin courseware/exam dumps apapun
- [ ] Referensi publik >= 3 (bila menambah cheatsheet baru)
- [ ] Command dites atau sudah diperiksa via tool versi terkini
- [ ] Markdown lulus markdownlint-cli2 (auto di CI)
- [ ] Shell scripts lulus `shellcheck` (bila ada)
- [ ] Link internal tetap valid
