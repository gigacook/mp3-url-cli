# ytmp3 🎧

Paste a link, get an mp3. A thin wrapper around **yt-dlp** (brew) + **ffmpeg**.

> It's 2026 and you still want an mp3. We respect it. We don't ask questions.
> The iPod Classic in your drawer respects it too.

Built for the ancient ritual of *"I just want this one song on my computer"*,
minus the sketchy converter site with seven fake DOWNLOAD buttons and a pop-up
telling you your Mac has 13 viruses.

## Install

```sh
./install.sh
```

That does two things:

1. `brew install yt-dlp ffmpeg` — the actual downloader and audio converter.
2. Creates **symlinks** at `/opt/homebrew/bin/mp3` and `/opt/homebrew/bin/ytmp3`
   pointing back at the `ytmp3` file in this folder. A symlink is just a
   shortcut: the file stays here, but because `/opt/homebrew/bin` is on your
   `PATH`, you can type `mp3` from any directory and the shell follows the
   shortcut to this script. Edit the script here and the command changes
   immediately — nothing is copied. Remove them any time with
   `rm /opt/homebrew/bin/mp3 /opt/homebrew/bin/ytmp3`.

Don't want that? Skip `install.sh` and run `./ytmp3` from inside this folder.

## Use

```sh
mp3 <url>                   # the everyday one
mp3 <url> <url> <url>       # several at once
mp3 <url> -s                # pick where to save it (menu)
mp3 <url> -q                # quiet: print only the saved path
mp3 -i                      # paste a batch of links, blank line to start
pbpaste | mp3               # whatever's on the clipboard
cat links.txt | mp3         # batch from a file
```

Typing **`mp3`** on its own prints a short summary: what it is, how to use it,
where files land, and where this folder lives.

`ytmp3` is the same command under its long name — both point at this script.

### Options

| flag | what it does |
|---|---|
| `-s`, `--saveas` | ask where to save, from a 4-item menu |
| `-q`, `--quiet` | print only the saved file path, nothing else |
| `-o`, `--out DIR` | save straight to `DIR`, no questions |
| `-i`, `--interactive` | paste-a-batch mode |
| `-h`, `--help` | the summary screen |

Env: `YTMP3_DIR`.

There is no quality flag — see [Audio quality](#audio-quality) for why.

### `-s` — pick a folder

```
$ mp3 https://… -s
where should it go?
  1  default    …/9_ytmp3/downloads
  2  music      ~/Music
  3  downloads  ~/Downloads
  4  desktop    ~/Desktop
→ choose 1-4 [1]
```

Enter alone takes the default. A bad entry just asks again. Because it has to
ask you something, `-s` can't be combined with `-q` (in either order) — that
errors out instead of guessing.

### `-q` — quiet

Prints exactly one line per file, the path it saved to, and nothing else — no
header, no progress bar, no tally. Failures still report a reason on stderr.
Exit status is 0 if everything worked, 1 if anything failed, so it drops
straight into scripts:

```sh
f=$(mp3 "$url" -q) && open "$f"
```

## Where files go

By default `downloads/` next to the script — created on first run, and found
via the script's real location, so it works through the symlink too.

Filenames are `YYYY-MM-DD Title.mp3` using the video's **upload date** (falls
back to today's date if the site doesn't report one):

```
downloads/2026-03-14 Some Track Name.mp3
```

Every finished file prints its full path in the terminal:

```
[1/1] https://…
✓ saved
  /Users/you/Documents/Claude/sandBox/9_ytmp3/downloads/2026-03-14 Some Track.mp3
```

## When a link doesn't work

yt-dlp's error wall gets boiled down to one plain sentence, with the raw line
underneath in grey if you want the detail:

```
! Link is dead — 404, nothing there
! Link is private
! Link is members-only
! Link is age-restricted — needs a signed-in account
! Link is region-locked — not available where you are
! Site not found — check the address, or your connection
```

Also covers: uploader-deleted, taken down, copyright blocks, live/upcoming
streams, unsupported links, and failed mp3 conversion. Anything unrecognised
falls back to *"Couldn't download this one"* plus the raw error.

In a batch, one bad link doesn't stop the rest — you get a tally at the end and
a non-zero exit if anything failed.

## Audio quality

Automatic, not configurable. Two settings do the work:

```
--format 'bestaudio[audio_channels<=?2]/bestaudio/best'
--audio-quality 0
```

**Video resolution has nothing to do with it.** YouTube ships audio as separate
audio-only streams (DASH); the video formats carry no audio at all. `yt-dlp -F`
on any video shows the split — 144p through 4K on one side, `audio only` rows on
the other. So there's no 480p-gets-you-the-good-AAC trade-off to make: the tool
downloads the audio stream and never fetches a single frame of video.

What YouTube actually offers, per stream:

| itag | codec | bitrate | notes |
|---|---|---|---|
| 249 / 250 | opus | ~50k / ~70k | low |
| 139 | aac | ~49k | low |
| 140 | aac | ~129k | the classic stereo one |
| 251 | opus | ~130k | **what we take** — better than aac at the same rate |
| 256 / 258 | aac | ~195k / ~388k | 5.1 surround, when present |

The `audio_channels<=?2` cap is the resource saver: on a video that has the 5.1
stream, taking stereo opus pulls **9.7 MiB instead of 29.3 MiB** for an
identical-sounding stereo mp3 — the surround stream would only get downmixed
anyway. The `?` means "keep formats that don't report channels", so sites other
than YouTube still work.

`--audio-quality 0` is LAME **V0**, roughly 245 kbps VBR — the top mp3 setting,
not 192. A real run measures 254 kbps. Since the source is already lossy
(~130k opus), V0 isn't chasing detail that isn't there; it's making sure the
mp3 encoder doesn't stack fresh artifacts on top of the ones already baked in.
V0 costs a few MB more than V2 and removes the question entirely.

For the record: 192 kbps mp3 is generally *near-transparent* — LAME V2 (~190k)
is the usual "can't tell it apart" reference point. It was never the weak link
here, and the pipeline was never producing it.

## What it does

- audio-only download → mp3 at LAME V0 (~245k VBR), automatically
- embeds cover art + metadata (title/artist)
- `--no-playlist`, so one link = one file; no `.part` leftovers
- yt-dlp's normal progress bar, plus a final tally of ok/failed

## Ghostty note

Nothing special needed — Ghostty pastes multi-line safely (bracketed paste), so
dropping a block of links into `mp3 -i` works: each line becomes one job.
