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

`subs` is a **terminal command, not an app you double-click.** You run it by
typing its name in Terminal (see below), not from Finder and not with
`open -a subs` (that only works for `.app` bundles and will say it can't find
it).

### Easiest: the `.pkg` installer (recommended)

Double-click `subs-vX.Y.Z.pkg` and follow the prompts. macOS asks for your
Mac login password once during install (in a normal dialog box, where you can
see it accepting what you type). Then open Terminal and run it from anywhere:

```
subs
```

**Why does it ask for my password?** The installer is copying `subs` into a
protected system folder (`/usr/local/bin`), so macOS asks for your Mac login
password once, during install. That's the operating system guarding the
folder, not `subs` doing anything online. The app itself never asks for a
login, API key, or account. Once it's installed, just run `subs` — no `sudo`,
no password.

### Alternative: a raw binary (`.zip`)

If you got a `.zip` instead of a `.pkg`, you don't have to install anything —
you can run it right where it is. Unzip it, then in Terminal go to that folder
and run it:

```
cd ~/Downloads        # wherever you unzipped it
./subs
```

The binary isn't signed by Apple, so the first time macOS may say the
developer can't be verified. Clear that once, then run it again:

```
xattr -d com.apple.quarantine ./subs
./subs
```

(Or: right-click the file in Finder → Open the first time, and confirm.)

That's enough to use it — `./subs` from its folder needs no admin password.
Only if you want to type plain `subs` from any folder do you move it onto your
PATH, which needs an administrator account:

```
sudo mv ./subs /usr/local/bin/subs
```

**Note:** when Terminal asks for a password (for `sudo`), nothing shows as you
type — no dots, no stars. It is taking it; type it and press Return. If it
keeps saying "Sorry, try again," check Caps Lock, or your account may not be
an administrator — in that case skip the move and just run `./subs` from its
folder, or use the `.pkg` installer above.

## Using it

Run `subs`, point it at a `.srt` file or a folder of them, pick your target
languages from the list, and let it go. It writes a new file per language
next to the original (for example `movie.srt` → `movie.es.srt`) and never
touches timestamps — only the subtitle text is translated.

## If a language isn't in the list

It means that pack isn't installed yet. Add it in System Settings (see above),
then restart `subs`.
