# subs

[![Latest release](https://img.shields.io/github/v/release/adamjohnlea/subs?label=release&sort=semver)](https://github.com/adamjohnlea/subs/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B%20·%20Apple%20Silicon-lightgrey)](https://github.com/adamjohnlea/subs/releases/latest)

Translate English `.srt` subtitle files into other languages, entirely on your Mac. subs uses Apple's on-device Translation framework, so nothing leaves the machine: no network, no upload, no API keys, no accounts. It runs as a small terminal app built with [SwiftTUI](https://swifttui.sh).

v1 is pick-and-go: point it at a subtitle file or a folder, pick your target languages, watch it run, done.

> **Before you download:** subs needs **macOS 26 (Tahoe) or newer, on an Apple Silicon Mac.** On an older macOS it won't launch — it aborts at startup with a `dyld` error like *"built for macOS 26.0 which is newer than running OS."* That's not a bug; the on-device translation it relies on only exists on macOS 26+. If you're on an older version, update to Tahoe first (or it can't run on that Mac).

## Requirements

- An Apple Silicon Mac. The on-device translation models are built for Apple Silicon.
- macOS 26 or newer. (Built and tested on macOS 27.)
- Only if building from source: Xcode 26 or later, which includes the Swift 6.4 toolchain. A standalone Swift 6.4+ toolchain from [swift.org](https://www.swift.org/install/macos/) also works. Check with:
  ```bash
  swift --version
  ```
  You want Swift 6.4 or newer. The downloaded installer needs none of this.
- At least one English translation language pack installed (see the next section). subs only offers languages you already have.

## Install a translation language pack

This is the one setup step people miss, so do it first.

subs can only translate into language pairs that are already downloaded on your Mac. Apple gates the download behind a system window, which a terminal app can't open, so you install packs yourself once:

1. Open System Settings.
2. Go to Language & Region.
3. Under Translation Languages, add the languages you want (for example Spanish, French, German). Each one downloads the English pairing with it.

A few things worth knowing, because these downloads are large and occasionally stubborn:

- The packs are multi-GB bilingual bundles. The first download can take a while.
- Keep the Mac plugged in and awake, and off Low Data Mode and any VPN, while it downloads.
- If a download stalls (sits at zero with no progress for a long time), remove the language and add it again. That kicks off a fresh download.
- A reboot clears a wedged translation daemon if re-adding doesn't help.

If no packs are installed when you launch subs, it tells you so and points you back here rather than failing quietly.

## Get it and run it

### Download the installer (easiest)

Grab the latest signed, notarized installer from the [releases page](https://github.com/adamjohnlea/subs/releases/latest):

1. Download `subs-vX.Y.Z.pkg`.
2. Double-click it and follow the prompts (macOS asks for your login password once, to install into `/usr/local/bin`).
3. Open a terminal and run it by typing just its name:

```bash
subs
```

`subs` is a terminal command, not an app you double-click — run it by typing `subs` (on its own, no `./`), not from Finder or with `open -a`. The installer puts it on your PATH, so it works from any folder.

It's signed with a Developer ID and notarized by Apple, so it runs with no Gatekeeper warnings and needs no Xcode or Swift toolchain. All you need is an Apple Silicon Mac on macOS 26+ with at least one language pack installed (above). Full step-by-step and troubleshooting (including the raw-binary route) are in [INSTALL.md](INSTALL.md).

### Build from source

If you'd rather build it yourself, or want to hack on it, you'll need the Swift toolchain from Requirements above.

```bash
git clone https://github.com/adamjohnlea/subs.git
cd subs
swift run subs
```

(SSH also works: `git clone git@github.com:adamjohnlea/subs.git`.)

The first `swift run` fetches the one dependency (SwiftTUI 0.15.1) and compiles everything, so it's slower than later runs. After that, `swift run subs` starts in a second or two.

## How it works

subs walks you through four screens. A step tracker across the top (`● Choose input  ○ Languages  ○ Translate  ○ Done`) shows where you are, and a muted hint line at the bottom of every screen shows the keys you can press.

### 1. Choose input

Type or paste a path to a single `.srt` file or a folder of `.srt` files, or just drag the file or folder from Finder into the terminal. `~` is expanded, and paths with spaces work whether they're quoted or backslash-escaped (the way the terminal writes a dragged path), so `~/Movies/Arrival.en.srt` and a dragged `~/Courses/LUMINOR\ -\ Create\ a\ Camera` folder both work.

Press Return (or select Continue) to validate. subs checks that it can find at least one subtitle file and reads which target languages you have installed. If the path is empty, wrong, or has no `.srt` files, the reason shows in red inside the card, and you stay on this screen.

### 2. Languages

A checklist of every target language whose pack is installed, filtered from the full catalog below. Move with the arrow keys, press Space to toggle a language on or off, and watch the running count (`2 selected`). A filled violet marker means selected.

Press Return to translate once at least one language is selected. With nothing selected, Return does nothing. Press Esc to go back to the input screen.

If you have no packs installed, this screen explains how to add them instead of showing an empty list.

### 3. Translate

subs works through every file crossed with every language you picked. You get a live progress bar, a spinner on the current item, the file and language being worked on (`Arrival.en.srt  →  French`), a running count of finished units, and a list of completed units marked with a green check.

"Units" means one file translated into one language, so translating one file into three languages is three units. Press Control-C to cancel.

### 4. Done

A summary of the run. Each written file shows with a green check; each failure shows in red with the specific file, language code, and reason (for example a pack that turned out not to be installed). A one-line summary color-codes the totals: `3 written · 1 failed · ~/Movies/Arrival`.

One bad file or language never kills the run. The rest still process, and every outcome, good or bad, is reported here.

Press Return (or select Translate more) to start over.

## Output files

Translated files are written next to the original, with the language code inserted before the extension:

```
Arrival.en.srt   ->   Arrival.es.srt   (Spanish)
                      Arrival.fr.srt   (French)
```

Indices and timestamps are copied through byte for byte. Only the subtitle text is translated.

## Keyboard

| Key | What it does |
|-----|--------------|
| Arrow keys | Move within a list |
| Space | Toggle a language on the Languages screen |
| Return | Continue, translate, or start over, depending on the screen |
| Esc | Go back (Languages screen) |
| Control-C | Quit, or cancel a run in progress |

Every action is also a button you can select, so nothing is keyboard-only.

## Languages it can offer

The catalog subs draws from, filtered at runtime to whichever pairs you have installed:

Spanish, French, German, Italian, Portuguese, Dutch, Russian, Japanese, Korean, Chinese, Arabic, Hindi, Polish, Turkish, Ukrainian.

You'll only see the ones whose English pack is downloaded on your Mac.

## What it does not do

Stated plainly so there are no surprises:

- It can't download language packs for you. That's gated by Apple's system window, so you install packs once in System Settings (above).
- It handles `.srt` only. Other subtitle formats aren't supported.
- Inline formatting tags (`<i>`, `{\an8}`) and multi-line cues are best effort. Translation can reorder or drop them. Timestamps are always preserved; tag fidelity is not guaranteed.
- Progress is reported per unit (file times language), not per subtitle line.
- Pointing it at a folder that already contains translated output will re-translate those outputs too (`Arrival.es.srt` becomes `Arrival.es.es.srt`). Translate into a clean folder, or remove earlier outputs first.

## Development

Pure Swift Package Manager, no Xcode project file needed.

```bash
swift build      # build
swift test       # run the unit tests
swift run subs   # launch the app
```

A `Makefile` wraps the common tasks (`make build`, `make test`, `make run`). It also builds the distributable: `make zip` produces a raw binary to hand to someone directly, and `make dist` produces the signed, notarized `.pkg` that ships on the releases page (it needs an Apple Developer ID; see the config at the top of the Makefile). Run `make help` for the full list.

The project is two targets with a deliberate seam:

- `SubtitleKit` is a pure library: SRT parsing, language-availability checks, the translation pipeline, and file writing. It has no UI and no external dependencies, and it's where the unit tests live.
- `subs` is the SwiftTUI executable: the four screens, key handling, and progress. It calls into `SubtitleKit` and knows nothing about how translation works.

That split is what would let a future two-pane editor be a second UI over the same core rather than a rewrite. The only external dependency is SwiftTUI 0.15.1, used only by the `subs` target.

## Contributing

Contributions are welcome. The fork-and-pull-request flow, the pre-PR checklist (tests pass, zero warnings, keep the library/UI seam, stay on-device), and good places to start all live in [CONTRIBUTING.md](CONTRIBUTING.md). CI runs `swift build` and `swift test` on every pull request.

## Roadmap

- A workbench view: English and translation side by side, with per-cue editing and re-running.

Translating each file in a single batch call (for more speed on large files) shipped in [v0.1.1](https://github.com/adamjohnlea/subs/releases/tag/v0.1.1).

## License

MIT. See [LICENSE](LICENSE).
