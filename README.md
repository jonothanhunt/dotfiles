# dotfiles

Terminal setup: **Ghostty**, **tmux** and **Neovim** — one Gruvbox palette
across all three on a black background, and one scroll-speed calibration.

```
git clone https://github.com/jonothanhunt/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

Run `~/dotfiles/install.sh --dry-run` first if you want to see what it
would touch. It is safe to re-run: anything it would overwrite is moved
aside as `<name>.bak-<timestamp>` rather than deleted, and a dry run
makes no network requests at all.

## Platforms

The same one-liner on all three. The installer detects which it is on and
adjusts the parts that genuinely differ — nothing else changes.

| | Ghostty | tmux + Neovim | Font goes to |
|---|---|---|---|
| **Linux** | yes | yes | `~/.local/share/fonts` + `fc-cache` |
| **macOS** | yes | yes | `~/Library/Fonts` (no fontconfig) |
| **WSL2** | no official build | yes | both sides — see [`windows/`](windows/) |

**Native Windows is refused, deliberately.** Run under Git Bash or MSYS
the script stops and points at WSL: this repo is built on symlinks, which
need Developer Mode or an elevated shell there, and Ghostty has no
official Windows build to point you at regardless. On Windows the
terminal emulator is a separate, Windows-side choice —
[`windows/apply.ps1`](windows/) themes Windows Terminal to match.

On macOS, Ghostty reads `~/.config/ghostty/config` just as it does on
Linux, so the symlink is the same. It *also* reads a copy under
`~/Library/Application Support/com.mitchellh.ghostty/` **afterwards**,
and later files win — the installer warns if one is sitting there,
because a stray copy silently overriding this repo is a miserable thing
to debug.

---

## What it sets up

| | |
|---|---|
| `ghostty/config` | → `~/.config/ghostty/config` |
| `tmux/tmux.conf` | → `~/.config/tmux/tmux.conf` |
| `nvim/` | → `~/.config/nvim` |

Everything is symlinked, so editing a file here changes the live config
and `git pull` on another machine picks it up.

The installer also clones the [tmux-gruvbox](https://github.com/egel/tmux-gruvbox)
theme and installs JetBrainsMono Nerd Font, both of which the status bar
depends on.

## Colours

Gruvbox Dark Hard for the palette — cream `#ebdbb2` text, harvest gold,
burnt orange and olive — on Adwaita's dark background, `#222226`.

| Layer | Where it comes from |
|---|---|
| Ghostty | built-in `Gruvbox Dark Hard` theme, `background = #222226` after it |
| tmux | `egel/tmux-gruvbox` in `dark` (hex, not 256-colour) mode |
| Neovim | `ellisonleao/gruvbox.nvim`, `contrast = "hard"`, transparent |
| Windows Terminal | `windows/gruvbox.json`, the same values in its own format |

The background is the one value not taken from Gruvbox. `#222226` is what
libadwaita resolves `window_bg_color` to in dark mode, so the terminal is
the same shade as every other app on the desktop instead of a darker
rectangle among them. Gruvbox supplies everything else.

Two things follow from that. Adwaita's darks are faintly cool where
Gruvbox is warm, so this trades a little palette purity for matching the
desktop — a deliberate choice, and nearly invisible at this lightness.
And the value is Adwaita's, not ours, so it is worth re-checking after a
GNOME upgrade; `ghostty/config` carries the one-liner that prints it.

The desktop is otherwise stock GNOME. **This repo themes the terminal
only** — no GTK themes, no shell themes, nothing that reaches outside
these three programs.

Neovim is transparent rather than painting its own background, which is
what keeps an editor pane and a shell pane on one ground — and means it
follows if `#222226` ever changes. Its statusline and the tmux bar below
it share a colour (`#3c3836`), so the two read as a single strip.

## No keybindings are rebound

Ghostty and tmux both run **entirely stock keys**. Nothing here overrides
a shortcut, so the official docs and any tutorial apply verbatim — which
is the whole point. tmux prefix is `Ctrl+B`; windows and panes are
numbered from 0, as tmux ships.

The single exception is two mouse-wheel lines in `tmux.conf`, marked in
place, which pin tmux to one line per wheel event.

To find out what a key does:

| | |
|---|---|
| Ghostty | `ghostty +list-keybinds`, or `Ctrl+Shift+P` for a searchable palette |
| tmux | `Ctrl+B ?`, or `tmux list-keys \| grep -w c` |
| Neovim | `:map <key>`, or press `Space` and pause for which-key |

A keypress reaches **Ghostty first, then tmux, then Neovim** — each can
swallow it before the next sees it. That order is worth remembering when
a key seems dead.

## Scroll speed

Three layers stack, so two are pinned to 1 and one is the live knob:

| Layer | Setting | Value |
|---|---|---|
| Ghostty | `mouse-scroll-multiplier` | **0.6** ← the knob |
| tmux | wheel binding `-N` | 1 |
| Neovim | `mousescroll` | `ver:1` |

Too fast? Lower the Ghostty number toward 0.4. Detents that do nothing at
all mean it floored a sub-step to zero — raise it toward 1.0.

## Neovim

Lazy.nvim, installing itself on first launch. Leader is `Space`.

| | |
|---|---|
| `Space f f` / `f g` / `f b` | Telescope: files, live grep, buffers |
| `Space e` | File tree |
| `Tab` | Accept Copilot suggestion |

Colourscheme is Gruvbox with a transparent background, so it inherits
Ghostty's.

## Per-machine notes

Ghostty's `window-decoration`, `maximize` and `window-padding-*` apply to
**new windows only** — reloading the config will not move an open one.

`font-size = 13` and `mouse-scroll-multiplier = 0.6` are tuned for a
particular display and mouse. They are the two lines most likely to want
changing on a different machine.
