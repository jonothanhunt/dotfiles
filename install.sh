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
#
# Runs on Linux, macOS and WSL. Native Windows is not a target — see the
# note in the platform block below, and windows/ for the Windows side.

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

# ── Platform ─────────────────────────────────────────────────────────
# Three supported hosts, and one that is deliberately refused.
#
# WSL is detected separately from Linux not because the configs differ —
# they are identical — but because the *font* lives on the other side of
# the boundary: Windows Terminal renders the glyphs, and it reads the
# Windows font store, not this filesystem.
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
      OS=wsl
    else
      OS=linux
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # Git Bash and MSYS can run this script, but the whole thing is built
    # on symlinks, which need Developer Mode or an elevated shell there —
    # and Ghostty has no official Windows build to point them at anyway.
    # WSL is the supported route, and it is a better one.
    die "native Windows (Git Bash/MSYS) is not supported — install WSL2 and run this inside it. See windows/README.md for the Windows Terminal side."
    ;;
  *) OS=unknown ;;
esac

# Where a user font goes, and whether anything has to be told about it.
# macOS reads ~/Library/Fonts directly and has no fontconfig; Linux and
# WSL use the XDG directory and need fc-cache run over it.
case "$OS" in
  macos) FONT_ROOT="$HOME/Library/Fonts" ;;
  *)     FONT_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
esac

(( DRY )) && say "${bold}DRY RUN${off} — nothing will be changed"
say ""
say "${bold}Platform:${off} $OS"

# ── link <source-in-repo> <destination> ──────────────────────────────
# Idempotent: correct symlink is left alone, anything else is backed up.
#
# The comparison avoids `readlink -f` as its first move: that is a GNU
# extension, and the BSD readlink macOS ships did not have it for years.
# Since this script is what created the link, comparing the literal
# target is both exact and portable; -f is only tried as a second chance,
# for a link someone made by hand via a different path to the same file.
already_linked() {
  local dst="$1" src="$2"
  [[ -L "$dst" ]] || return 1
  [[ "$(readlink "$dst")" == "$src" ]] && return 0
  if readlink -f / >/dev/null 2>&1; then
    [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]] && return 0
  fi
  return 1
}

link() {
  local src="$REPO/$1" dst="$2"
  [[ -e "$src" ]] || die "missing in repo: $1"

  if already_linked "$dst" "$src"; then
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

# Ghostty reads the XDG path on macOS too, so the link above is correct
# there — but it also reads an Application Support copy *afterwards*, and
# later files win. A stray one silently overrides everything this repo
# does, which is a miserable thing to debug, so say so plainly.
if [[ "$OS" == macos ]]; then
  MACCFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ -e "$MACCFG" ]]; then
    warn "$MACCFG exists and is loaded AFTER the linked config — it will override it"
    warn "  move it aside if Ghostty ignores this repo's settings"
  fi
fi

# ── Gruvbox, the one tmux plugin ─────────────────────────────────────
# Cloned rather than vendored so it can be updated with a git pull, and
# kept out of this repo (see .gitignore) so there is no submodule to
# keep in step.
say ""
say "${bold}2. tmux theme${off}"
GRUVBOX="$CONFIG/tmux/plugins/tmux-gruvbox"
if [[ -d "$GRUVBOX/.git" ]]; then
  skip "tmux-gruvbox already cloned — update with: git -C $GRUVBOX pull"
else
  run mkdir -p "$(dirname "$GRUVBOX")"
  run git clone --depth 1 https://github.com/egel/tmux-gruvbox.git "$GRUVBOX"
  ok "tmux-gruvbox cloned"
fi

# ── Font ─────────────────────────────────────────────────────────────
# The Nerd Font variant carries the powerline separators and icons the
# tmux status bar draws. Without it the bar renders as tofu boxes.
say ""
say "${bold}3. Font${off}"

# Two ways of asking, because only one works everywhere. fontconfig is
# authoritative where it exists (Linux, WSL) and absent on macOS, so
# there the files themselves are the only evidence available.
#
# Note the redirect rather than `grep -q`: -q makes grep exit on the
# first match, which hands the upstream command a SIGPIPE, and
# `set -o pipefail` then reports the whole pipeline as 141. That read as
# "font missing" and re-downloaded the archive on every single run.
font_installed() {
  if command -v fc-list >/dev/null 2>&1; then
    fc-list : family 2>/dev/null | grep -i 'JetBrainsMono Nerd Font' >/dev/null && return 0
  fi
  compgen -G "$FONT_ROOT/JetBrainsMonoNerdFont/*.ttf" >/dev/null 2>&1 && return 0
  compgen -G "$FONT_ROOT/JetBrainsMono*NerdFont*.ttf" >/dev/null 2>&1 && return 0
  return 1
}

if font_installed; then
  skip "JetBrainsMono Nerd Font already installed"
elif ! command -v curl >/dev/null; then
  warn "curl not found — install JetBrainsMono Nerd Font manually"
else
  FONTDIR="$FONT_ROOT/JetBrainsMonoNerdFont"
  PINNED="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/JetBrainsMono.tar.xz"
  if (( DRY )); then
    # No network call here on purpose. Asking GitHub which release is
    # latest is a request, and --dry-run should be runnable offline and
    # observably do nothing at all.
    printf '  %swould:%s download the latest JetBrainsMono Nerd Font (or %s) → %s\n' "$dim" "$off" "$PINNED" "$FONTDIR"
  else
    # Every step of resolving the URL is allowed to fail into the pinned
    # release, which is the whole point of having one. Two things make
    # that harder than it looks, and both used to abort the script under
    # `set -e` instead of falling back:
    #   - no network at all, so curl exits non-zero;
    #   - `head -1` closing the pipe once it has its line, which SIGPIPEs
    #     grep and makes `set -o pipefail` report 141 for a pipeline that
    #     did exactly what was wanted.
    URL=""
    if RAW="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest 2>/dev/null)"; then
      URL="$(printf '%s' "$RAW" | grep -o 'https://[^"]*JetBrainsMono\.tar\.xz' | head -1 || true)"
    fi
    if [[ -z "$URL" ]]; then
      URL="$PINNED"
      warn "could not resolve the latest release — using the pinned one"
    fi
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    mkdir -p "$FONTDIR"
    curl -fsSL -o "$TMP/f.tar.xz" "$URL"
    # --wildcards is a GNU tar option. macOS ships bsdtar, which treats
    # the pattern as a glob by default and errors out on the flag, so the
    # flag has to be conditional rather than always passed.
    if tar --version 2>/dev/null | grep -i 'gnu' >/dev/null; then
      tar -xJf "$TMP/f.tar.xz" -C "$FONTDIR" --wildcards '*.ttf'
    else
      tar -xJf "$TMP/f.tar.xz" -C "$FONTDIR" '*.ttf'
    fi
    # macOS has no fontconfig and picks up ~/Library/Fonts on its own.
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$FONT_ROOT" >/dev/null 2>&1 || true
    fi
    ok "JetBrainsMono Nerd Font installed → $FONTDIR"
  fi
fi

# Under WSL the font just installed is invisible to Windows Terminal:
# the glyphs are drawn by a Windows process reading the Windows font
# store, and this filesystem is not it. It is only useful here for GUI
# apps running under WSLg.
if [[ "$OS" == wsl ]]; then
  warn "WSL: Windows Terminal reads the *Windows* font store, not this one"
  warn "  install the font on the Windows side too — see windows/README.md"
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
    # Not a failure anywhere, and expected on WSL: there is no official
    # Windows build, so the terminal emulator is a Windows-side choice
    # and ghostty/config simply goes unread on that machine.
    if [[ "$OS" == wsl ]]; then
      skip "ghostty not installed — expected on WSL, see windows/README.md"
    else
      warn "ghostty not installed — see ghostty.org/download"
    fi
  else
    warn "$c not installed"
  fi
done
# The status bar's branch segment shells out to these two. git is already
# checked above; sed is the one that supplies the branch glyph.
for c in sed; do command -v "$c" >/dev/null || warn "$c missing (the status bar's git branch needs it)"; done

say ""
if (( DRY )); then
  say "${bold}Dry run complete.${off} Re-run without --dry-run to apply."
else
  say "${bold}Done.${off}"
  say ""
  say "  Reload tmux    ${dim}tmux kill-server${off}   (or source the conf in a running one)"
  if [[ "$OS" == wsl ]]; then
    say "  Terminal       ${dim}run windows/apply.ps1 on the Windows side${off}"
  else
    say "  Reload Ghostty ${dim}open a new window${off}  — padding and decoration apply per-window"
  fi
  say "  Neovim         ${dim}plugins install themselves on first launch${off}"
fi
