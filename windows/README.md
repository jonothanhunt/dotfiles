# Windows

Ghostty has **no official Windows build**. The project distributes
prebuilt binaries for macOS and leaves Linux to distro packagers;
Windows is not a target. So on Windows the stack splits in two:

| | |
|---|---|
| **tmux + Neovim** | run inside WSL2, from `install.sh` — identical to Linux |
| **the terminal itself** | a Windows program, themed separately by `apply.ps1` |

`ghostty/config` simply goes unread on such a machine. That is expected,
and `install.sh` says so rather than warning about it.

## Setup

**1. In WSL** — the same one-liner as everywhere else:

```bash
git clone https://github.com/jonothanhunt/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

It detects WSL and adjusts: the font it installs is only useful to WSLg
GUI apps, so it points you here for the Windows side.

**2. In PowerShell, on the Windows side** — not inside WSL:

```powershell
.\windows\apply.ps1
.\windows\apply.ps1 -DryRun    # show what would happen
```

This installs JetBrainsMono Nerd Font for the current user (no admin
needed) and merges the colour scheme into Windows Terminal, backing up
`settings.json` first.

## Why the font has to be installed twice

The glyphs in the tmux status bar — the powerline separators, the git
branch marker — are drawn by whichever process owns the screen. Under
WSL that is **Windows Terminal, a Windows program**, reading the Windows
font store. A font installed inside the WSL filesystem is invisible to
it, and the bar renders as tofu boxes.

So the font goes in twice: once inside WSL (where it does nothing unless
you run GUI apps through WSLg) and once on Windows (where it does the
actual work). `apply.ps1` handles the second.

## The palette

`gruvbox.json` is Windows Terminal's scheme format, carrying the same
twenty values Ghostty resolves from its built-in `Gruvbox Dark Hard`
theme, with the background set to `#222226`. Both sides are checked
against each other rather than transcribed by eye — `background`,
`foreground`, `cursorColor`, `selectionBackground` and all sixteen ANSI
slots match exactly.

That background is GNOME's Adwaita dark window colour, which on Windows
means nothing at all — there is no Adwaita here to match. It is used
anyway so the terminal is the same shade on every machine rather than
subtly different on one of them. If you would rather this box used
Gruvbox's own ground instead, change `background` to `#1d2021`; nothing
else in the scheme depends on it.

Note the mapping: Windows Terminal calls ANSI 5 `purple` and ANSI 6
`cyan`, where Gruvbox calls them purple and aqua. Same values, different
labels.

If `apply.ps1` reports that it could not parse `settings.json`, that is
working as intended: Windows Terminal ships the file as JSONC, full of
`//` comments, and a regex that strips those cannot reliably tell a
comment from the `//` inside an `https://` URL. Rather than risk
mangling the file it stops and asks you to paste the scheme in by hand,
via **Settings → Open JSON file**.

## Alternatives to WSL

Community native Windows ports of Ghostty appeared during 2026 —
[winghostty](https://winghostty.com/),
[Thr45hx/ghostty-windows](https://github.com/Thr45hx/ghostty-windows),
[shiweis/ghostty-windows](https://github.com/InsipidPoint/ghostty-windows).
None are from the Ghostty maintainers, and none are verified here. If you
use one and it reads `~/.config/ghostty/config`, this repo's Ghostty
config may work as-is — but treat that as an experiment, not a supported
path.

## Not tested here

`apply.ps1` was written against Microsoft's documented settings
locations and the per-user font registration under
`HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts`, but it has
**not been run on a Windows machine**. The colour values in
`gruvbox.json` *are* verified. Everything the script touches is
backed up first, and it prints the restore command on the way out.
