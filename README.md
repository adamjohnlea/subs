# subs

Translate English `.srt` subtitle files into other languages, entirely on your Mac. subs uses Apple's on-device Translation framework, so nothing leaves the machine: no network, no upload, no API keys, no accounts. It runs as a small terminal app built with [SwiftTUI](https://swifttui.sh).

v1 is pick-and-go: point it at a subtitle file or a folder, pick your target languages, watch it run, done.

## Requirements

- An Apple Silicon Mac. The on-device translation models are built for Apple Silicon.
- macOS 26 or newer. (Built and tested on macOS 27.)
- Xcode 26 or later, which includes the Swift 6.4 toolchain. A standalone Swift 6.4+ toolchain from [swift.org](https://www.swift.org/install/macos/) also works. Check with:
  ```bash
  swift --version
  ```
  You want Swift 6.4 or newer.
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

The repository is private, so you'll need access to clone it.

```bash
git clone git@github.com:adamjohnlea/subs.git
cd subs
swift run subs
```

(HTTPS also works: `git clone https://github.com/adamjohnlea/subs.git`.)

The first `swift run` fetches the one dependency (SwiftTUI 0.15.1) and compiles everything, so it's slower than later runs. After that, `swift run subs` starts in a second or two.

## How it works

subs walks you through four screens. A step tracker across the top (`● Choose input  ○ Languages  ○ Translate  ○ Done`) shows where you are, and a muted hint line at the bottom of every screen shows the keys you can press.

### 1. Choose input

Type or paste a path to either a single `.srt` file or a folder that contains `.srt` files. `~` is expanded, so `~/Movies/Arrival/Arrival.en.srt` works.

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

The project is two targets with a deliberate seam:

- `SubtitleKit` is a pure library: SRT parsing, language-availability checks, the translation pipeline, and file writing. It has no UI and no external dependencies, and it's where the unit tests live.
- `subs` is the SwiftTUI executable: the four screens, key handling, and progress. It calls into `SubtitleKit` and knows nothing about how translation works.

That split is what would let a future two-pane editor be a second UI over the same core rather than a rewrite. The only external dependency is SwiftTUI 0.15.1, used only by the `subs` target.

## Contributing

Contributions are welcome. A few things will make yours land smoothly.

Getting set up is the same as running the app: see Requirements and the setup steps above. You'll want the toolchain and at least one translation language pack installed so you can exercise the translation path by hand.

Before you open a pull request:

- `swift build` and `swift test` both pass, with no new warnings. The project holds a zero-warning bar and builds under Swift 6 strict concurrency.
- New logic in `SubtitleKit` comes with tests. That's where the testable work lives (parsing, path derivation, the pipeline). The `subs` UI target is verified by running it, since terminal rendering isn't unit-tested.
- Keep the seam intact. `SubtitleKit` stays UI-free with no external dependencies; anything terminal-facing belongs in `subs`. A feature that needs both gets split along that line.
- Keep it on-device. No network calls and no third-party services. The whole point is that subtitles never leave the machine.
- Match the surrounding style, and keep commits small and focused with clear messages.

For anything large or design-changing, open an issue first so we can agree on the approach before you build it.

Good places to start: the roadmap items below, better inline-tag handling (see the limitations above), or an additional subtitle format behind the existing parser seam.

## Roadmap

Possible next steps, not promises:

- A workbench view: English and translation side by side, with per-cue editing and re-running.
- Moving the translator to Apple's batch translation API for more speed on large files.
