# Installing subs

`subs` translates English `.srt` subtitle files into other languages using
Apple's on-device translation. Nothing leaves your Mac — no network, no API
keys, no accounts.

## What you need

- **An Apple Silicon Mac** (M1 or later).
- **macOS 26 (Tahoe) or later.** Earlier versions won't run it.
- **At least one translation language pack installed.** `subs` only lists
  languages you've already downloaded. Install them first:
  **System Settings → General → Language & Region → Translation Languages → +**
  and add the languages you want. This download is large and can be slow;
  keep the Mac plugged in and awake while it runs.

## Install

### If you got a `.pkg`

Double-click it and follow the prompts. It installs `subs` to
`/usr/local/bin`, so you can then run it from any terminal:

```
subs
```

### If you got a `.zip`

The binary isn't signed by Apple, so macOS quarantines it on download. Unzip
it, then clear the quarantine flag once:

```
unzip subs-*-arm64.zip
xattr -d com.apple.quarantine ./subs
./subs
```

(Or: right-click the file in Finder → Open the first time, and confirm.)

To run it from anywhere, move it onto your PATH:

```
sudo mv ./subs /usr/local/bin/subs
```

## Using it

Run `subs`, point it at a `.srt` file or a folder of them, pick your target
languages from the list, and let it go. It writes a new file per language
next to the original (for example `movie.srt` → `movie.es.srt`) and never
touches timestamps — only the subtitle text is translated.

## If a language isn't in the list

It means that pack isn't installed yet. Add it in System Settings (see above),
then restart `subs`.
