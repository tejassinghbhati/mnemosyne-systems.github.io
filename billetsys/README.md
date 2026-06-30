# billetsys website

Marketing and documentation site for [billetsys](https://github.com/mnemosyne-systems/billetsys),
a modern open-source support ticket solution.

## Structure

```
billetsys/
├── index.html          Landing page
├── features.html       Feature overview
├── install.html        Installation / getting started
├── releases.html       Release history
├── style.css           Site styles (crimson brand, light/dark)
├── border-glow.js      Card hover glow effect
├── copy-code.js        Copy-to-clipboard helper
├── logo.svg / logo.png Brand logo
└── doc/                Generated documentation (see below)
    ├── generate.sh     Builds doc/*.html from the upstream manual with pandoc
    ├── template.html   Pandoc HTML template (nav + sidebar + TOC)
    ├── doc.css         Documentation styles
    ├── logo/           Logo assets used by the docs
    ├── images/         Manual screenshots
    └── *.html          One page per manual chapter
```

## Regenerating the documentation

The `doc/` HTML pages are generated from the billetsys
[Markdown manual](https://github.com/mnemosyne-systems/billetsys/tree/main/doc/manual/en)
with [pandoc](https://pandoc.org/). To rebuild after the upstream manual changes:

```sh
cd doc
./generate.sh
```

Requirements: `pandoc` and an authenticated `gh` CLI (used to fetch the manual
Markdown and its images from the repository).

The script renders one HTML page per chapter using `template.html` and `doc.css`,
wires up the sidebar active state, the per-page "On this page" table of contents,
and the prev/next footer links.
