# Contributing to subs

Contributions are welcome. A few things will make yours land smoothly.

## Getting set up

Setup is the same as running the app. See [Requirements](README.md#requirements) and the steps under [Install a translation language pack](README.md#install-a-translation-language-pack) and [Build from source](README.md#build-from-source) in the README. You'll want the Swift toolchain and at least one translation language pack installed, so you can exercise the translation path by hand.

```bash
git clone https://github.com/adamjohnlea/subs.git
cd subs
swift build      # build
swift test       # run the unit tests
swift run subs   # launch the app
```

## Before you open a pull request

- `swift build` and `swift test` both pass, with no new warnings. The project holds a zero-warning bar and builds under Swift 6 strict concurrency. CI runs both on every pull request, so a branch that doesn't build won't merge.
- New logic in `SubtitleKit` comes with tests. That's where the testable work lives: parsing, path derivation, the pipeline. The `subs` UI target is verified by running it, since terminal rendering isn't unit-tested.
- Keep the seam intact. `SubtitleKit` stays UI-free with no external dependencies; anything terminal-facing belongs in `subs`. A feature that needs both gets split along that line. See [Development](README.md#development) for what the split is and why.
- Keep it on-device. No network calls and no third-party services. The whole point is that subtitles never leave the machine.
- Match the surrounding style, and keep commits small and focused with clear messages.

For anything large or design-changing, open an issue first so we can agree on the approach before you build it.

## How changes get in

The repo uses the standard fork-and-pull-request flow:

1. Fork the repo and create a branch off `main`.
2. Make your change, with tests where the guidance above calls for them.
3. Push to your fork and open a pull request against `main`.
4. CI runs `swift build` and `swift test`. Keep them green.
5. A maintainer reviews, and once it's approved and checks pass, it merges.

## Good places to start

- The items on the [Roadmap](README.md#roadmap).
- Better inline-tag handling (see [What it does not do](README.md#what-it-does-not-do) in the README).
- An additional subtitle format behind the existing parser seam.
