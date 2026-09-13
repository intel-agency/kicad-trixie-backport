# kicad-trixie-backport

Unofficial **KiCad 10** packages for **Debian 13 "trixie"**, rebuilt in CI from Debian sid's own
source package and published as GitHub Release `.deb`s.

## Why

- Debian trixie ships KiCad **9.0.2**; trixie-backports has **9.0.8**. KiCad **10** currently exists
  only in sid (`kicad 10.0.6+dfsg-1`).
- KiCad publishes no apt repository for Debian (their repos are Ubuntu PPAs), and current-stable
  Linux releases are AppImage/Flatpak-only — not an option for everyone.
- Every KiCad 10 build dependency is satisfied by trixie, so Debian's own source package rebuilds
  cleanly: same code, same packaging, one changelog entry.

## Install

Grab `*.deb` + `SHA256SUMS` from the [latest release](../../releases/latest), then:

```bash
sha256sum -c SHA256SUMS
sudo apt install ./kicad_*_amd64.deb ./kicad-libraries_*_all.deb ./kicad-symbols_*_all.deb \
                 ./kicad-footprints_*_all.deb ./kicad-templates_*_all.deb ./kicad-demos_*_all.deb
```

What you get:

| Package | Origin |
|---|---|
| `kicad` (amd64: kicad, kicad-cli, pcbnew, python `_pcbnew`) | rebuilt on trixie by this repo's CI |
| `kicad-libraries`, `kicad-symbols`, `kicad-footprints`, `kicad-templates`, `kicad-demos` (arch:all) | Debian sid's own binaries, redistributed verbatim |

## Version policy

Rebuilds are re-versioned to sort **below** a future official backport (e.g. local
`10.0.6+dfsg-0~local1` < official `10.0.6+dfsg-1~bpo13+1`), while remaining above everything in
trixie and trixie-backports. When Debian publishes an official KiCad 10 backport, `apt upgrade`
moves you onto it automatically — this repo's packages step aside.

## Building your own

Actions tab → **build** → *Run workflow*. Inputs:

- `source_version` — the Debian sid source version to rebuild (default: the latest tested)
- `run_tests` — run the package test suite during the build (default: **off** — enable for release-quality builds; the suite is a large share of the build's runner minutes)
- `runner` — `ubuntu-latest` (free for public repos, slower) or a Blacksmith label such as `blacksmith-16vcpu-ubuntu-2404` when speed matters

The workflow runs in a `debian:trixie` container: build dependencies resolve **only** from trixie
(a temporary sid entry is used exclusively for fetch-only `apt-get download` of the arch:all data
packages, so no sid libraries ever enter the build). Each release links the exact Debian source
package it was built from.

## Caveats

- **Unofficial** — not supported by Debian or KiCad. Built from unmodified Debian sources, but
  you use these at your own risk.
- trixie **amd64** only.
- No `kicad-packages3d` (3D models) — install it separately from Debian if you want it.

## Licenses & source

- This repo's own files (workflow, docs): **MIT** — see [LICENSE](LICENSE).
- The binaries follow their upstream licenses: KiCad is GPL-3.0-or-later; symbol/footprint
  libraries are CC-BY-SA-4.0; Debian packaging under the terms in the source's
  `debian/copyright`.
- Complete corresponding source for every release: the linked `.dsc`/tarballs on
  `deb.debian.org` plus the pinned build recipe in this repo.
