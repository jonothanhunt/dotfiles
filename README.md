# dotfiles

Terminal setup: **Ghostty**, **tmux** and **Neovim** — one Dracula palette
across all three, and one scroll-speed calibration.

```
git clone https://github.com/jonothanhunt/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

Run `~/dotfiles/install.sh --dry-run` first if you want to see what it
would touch. It is safe to re-run: anything it would overwrite is moved
aside as `<name>.bak-<timestamp>` rather than deleted.

---

## What it sets up

| | |
|---|---|
| `ghostty/config` | → `~/.config/ghostty/config` |
| `tmux/tmux.conf` | → `~/.config/tmux/tmux.conf` |
| `nvim/` | → `~/.config/nvim` |

Everything is symlinked, so editing a file here changes the live config
and `git pull` on another machine picks it up.

The installer also clones the [Dracula](https://github.com/dracula/tmux)
tmux theme and installs JetBrainsMono Nerd Font, both of which the status
bar depends on.

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

Colourscheme is Dracula with a transparent background, so it inherits
Ghostty's.

## KDE Plasma (optional)

If you're on Plasma, this themes the desktop to match the terminal —
Dracula colours, JetBrainsMono throughout, and square window corners:

```
~/dotfiles/kde/apply.sh
~/dotfiles/kde/apply.sh --revert   # back to Breeze
```

Assets are pulled from [dracula/gtk](https://github.com/dracula/gtk)'s
`kde/` directory with a sparse checkout. Everything installs under
`~/.local/share` and `~/.config` — no sudo, nothing system-wide.

Colours and window decorations apply immediately; **fonts need a logout**,
because Qt reads them once when an application starts.

Square corners come from routing the decoration through Aurorae, which
Breeze does not expose a radius setting for.

Optionally `sudo dnf install kvantum` first and re-run — Kvantum restyles
the widgets themselves (buttons, scrollbars). Without it the colours
still apply, but widget *shapes* stay Breeze.

Unlike GNOME, Plasma has no libadwaita ceiling: the theme reaches the
whole desktop rather than stopping at the shell.

## Per-machine notes

Ghostty's `window-decoration`, `maximize` and `window-padding-*` apply to
**new windows only** — reloading the config will not move an open one.

`font-size = 13` and `mouse-scroll-multiplier = 0.6` are tuned for a
particular display and mouse. They are the two lines most likely to want
changing on a different machine.
