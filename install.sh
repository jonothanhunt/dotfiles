#!/usr/bin/env bash
#
# Bootstrap this terminal setup onto a machine.
#
#   git clone https://github.com/jonothanhunt/dotfiles ~/dotfiles
#   ~/dotfiles/install.sh
#
# Safe to run repeatedly: it only changes what is not already correct,
# and anything it would overwrite is moved aside with a .bak-<date>
# suffix rather than deleted.
#
#   --dry-run   show what would happen, change nothing

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$grn" "$off" "$*"; }
skip() { printf '  %s·%s %s\n' "$dim" "$off" "$*"; }
warn() { printf '  %s!%s %s\n' "$ylw" "$off" "$*"; }
die()  { printf '  %s✗%s %s\n' "$red" "$off" "$*" >&2; exit 1; }
run()  { if (( DRY )); then printf '  %swould:%s %s\n' "$dim" "$off" "$*"; else "$@"; fi; }

(( DRY )) && say "${bold}DRY RUN${off} — nothing will be changed"

# ── link <source-in-repo> <destination> ──────────────────────────────
# Idempotent: correct symlink is left alone, anything else is backed up.
link() {
  local src="$REPO/$1" dst="$2"
  [[ -e "$src" ]] || die "missing in repo: $1"

  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    skip "$dst already linked"
    return
  fi

  run mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    warn "$dst exists — moving to $(basename "$dst").bak-$STAMP"
    run mv "$dst" "$dst.bak-$STAMP"
  fi

  run ln -s "$src" "$dst"
  ok "$dst → $1"
}

say ""
say "${bold}1. Linking configs${off}"
link ghostty/config   "$CONFIG/ghostty/config"
link tmux/tmux.conf   "$CONFIG/tmux/tmux.conf"
link nvim             "$CONFIG/nvim"

# ── Dracula, the one tmux plugin ─────────────────────────────────────
# Cloned rather than vendored so it can be updated with a git pull, and
# kept out of this repo (see .gitignore) so there is no submodule to
# keep in step.
say ""
say "${bold}2. tmux theme${off}"
DRACULA="$CONFIG/tmux/plugins/dracula"
if [[ -d "$DRACULA/.git" ]]; then
  skip "dracula already cloned — update with: git -C $DRACULA pull"
else
  run mkdir -p "$(dirname "$DRACULA")"
  run git clone --depth 1 https://github.com/dracula/tmux.git "$DRACULA"
  ok "dracula cloned"
fi

# ── Font ─────────────────────────────────────────────────────────────
# The Nerd Font variant carries the powerline separators and icons the
# tmux status bar draws. Without it the bar renders as tofu boxes.
say ""
say "${bold}3. Font${off}"
if fc-list : family 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'; then
  skip "JetBrainsMono Nerd Font already installed"
elif ! command -v curl >/dev/null; then
  warn "curl not found — install JetBrainsMono Nerd Font manually"
else
  FONTDIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  URL="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep -o 'https://[^"]*JetBrainsMono\.tar\.xz' | head -1)"
  [[ -n "$URL" ]] || URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/JetBrainsMono.tar.xz"
  if (( DRY )); then
    printf '  %swould:%s download %s → %s\n' "$dim" "$off" "$URL" "$FONTDIR"
  else
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    mkdir -p "$FONTDIR"
    curl -fsSL -o "$TMP/f.tar.xz" "$URL"
    tar -xJf "$TMP/f.tar.xz" -C "$FONTDIR" --wildcards '*.ttf'
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    ok "JetBrainsMono Nerd Font installed"
  fi
fi

# ── What is missing ──────────────────────────────────────────────────
say ""
say "${bold}4. Checking dependencies${off}"
# tmux takes -V, not --version; the rest take --version.
version_of() {
  case "$1" in
    tmux) tmux -V 2>/dev/null ;;
    *)    "$1" --version 2>/dev/null | head -1 ;;
  esac
}

for c in ghostty tmux nvim git; do
  if command -v "$c" >/dev/null; then
    v="$(version_of "$c" | grep -oE '[0-9]+\.[0-9]+[a-z0-9.]*' | head -1)"
    ok "$c ${v:-installed}"
  elif [[ "$c" == ghostty ]]; then
    warn "ghostty not installed — see ghostty.org/download"
  else
    warn "$c not installed"
  fi
done
# Dracula's git widget shells out to these.
for c in bc jq; do command -v "$c" >/dev/null || warn "$c missing (dracula's git widget needs it)"; done

say ""
if (( DRY )); then
  say "${bold}Dry run complete.${off} Re-run without --dry-run to apply."
else
  say "${bold}Done.${off}"
  say ""
  say "  Reload tmux    ${dim}tmux kill-server${off}   (or source the conf in a running one)"
  say "  Reload Ghostty ${dim}open a new window${off}  — padding and decoration apply per-window"
  say "  Neovim         ${dim}plugins install themselves on first launch${off}"
fi
