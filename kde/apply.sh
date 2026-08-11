#!/usr/bin/env bash
#
# Dracula + JetBrainsMono across KDE Plasma, to match the terminal stack.
#
#   ~/dotfiles/kde/apply.sh
#   ~/dotfiles/kde/apply.sh --revert     # back to Breeze defaults
#
# Assets come from github.com/dracula/gtk (its kde/ directory), fetched
# with a sparse checkout so we pull a few hundred KB rather than the
# whole GTK theme.
#
# Everything installs under ~/.local/share and ~/.config — no sudo, and
# nothing here touches system files.

set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dracula-kde"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
FONT_UI="JetBrainsMono Nerd Font"
FONT_MONO="JetBrainsMono Nerd Font Mono"

bold=$'\033[1m'; dim=$'\033[2m'; grn=$'\033[32m'; ylw=$'\033[33m'; off=$'\033[0m'
ok()   { printf '  %s✓%s %s\n' "$grn" "$off" "$*"; }
warn() { printf '  %s!%s %s\n' "$ylw" "$off" "$*"; }
step() { printf '\n%s%s%s\n' "$bold" "$*" "$off"; }

[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || warn "not in a KDE session — settings will apply at next Plasma login"

# Qt font spec: family,size,pixelSize,styleHint,weight,italic,underline,
# strikeout,fixedPitch,rawMode. Weight 50 is normal.
font() { printf '%s,%s,-1,5,50,0,0,0,0,0' "$1" "$2"; }

set_font() { kwriteconfig6 --file kdeglobals --group "$1" --key "$2" "$3"; }

# ── Revert ───────────────────────────────────────────────────────────
if [[ "${1:-}" == "--revert" ]]; then
  step "Reverting to Breeze"
  plasma-apply-colorscheme BreezeLight >/dev/null 2>&1 || true
  plasma-apply-desktoptheme default    >/dev/null 2>&1 || true
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
  for k in font:10 menuFont:10 toolBarFont:9 smallestReadableFont:8; do
    set_font General "${k%%:*}" "$(font 'Noto Sans' "${k##*:}")"
  done
  set_font General fixed "$(font 'Noto Sans Mono' 10)"
  set_font WM activeFont "$(font 'Noto Sans' 10)"
  dbus-send --session --dest=org.kde.KWin --type=method_call /KWin org.kde.KWin.reconfigure 2>/dev/null || true
  ok "reverted — log out and back in to finish"
  exit 0
fi

# ── 1. Fetch ─────────────────────────────────────────────────────────
step "1. Fetching Dracula KDE assets"
if [[ -d "$CACHE/.git" ]]; then
  git -C "$CACHE" pull -q --ff-only 2>/dev/null || true
  ok "cache updated"
else
  mkdir -p "$CACHE"
  git clone -q --depth 1 --filter=blob:none --sparse https://github.com/dracula/gtk.git "$CACHE"
  git -C "$CACHE" sparse-checkout set kde
  ok "cloned"
fi
SRC="$CACHE/kde"

# ── 2. Install ───────────────────────────────────────────────────────
step "2. Installing themes"
install_into() {           # install_into <dest> <src...>
  local dest="$1"; shift
  mkdir -p "$dest"
  cp -rT "$1" "$dest/$(basename "$1")" 2>/dev/null || cp -r "$1" "$dest/"
}

mkdir -p "$SHARE/color-schemes" "$SHARE/aurorae/themes" "$SHARE/plasma/desktoptheme" "$SHARE/icons"
cp -f "$SRC"/color-schemes/*.colors        "$SHARE/color-schemes/";              ok "colour schemes"
cp -rf "$SRC"/aurorae/Dracula              "$SHARE/aurorae/themes/";             ok "window decoration"
cp -rf "$SRC"/plasma/desktoptheme/Dracula* "$SHARE/plasma/desktoptheme/";        ok "panel theme"
cp -rf "$SRC"/cursors/Dracula-cursors      "$SHARE/icons/" 2>/dev/null && ok "cursors"

# Kvantum styles the widgets themselves (buttons, scrollbars). Optional:
# without it Breeze draws the widgets, still using the Dracula colours.
if command -v kvantummanager >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/Kvantum"
  cp -rf "$SRC"/kvantum/Dracula-Solid "$HOME/.config/Kvantum/"
  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
  printf '[General]\ntheme=Dracula-Solid\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"
  ok "kvantum widget style"
else
  warn "kvantum not installed — widgets stay Breeze-shaped (colours still apply)"
  warn "  optional: sudo dnf install kvantum, then re-run this script"
fi

# ── 3. Apply ─────────────────────────────────────────────────────────
step "3. Applying"
plasma-apply-colorscheme Dracula >/dev/null && ok "colour scheme → Dracula"

# Dracula-Solid has an opaque panel; the plain "Dracula" theme is
# translucent. Solid keeps the panel reading as one flat block, which is
# closer to a status bar than a floating widget.
plasma-apply-desktoptheme Dracula-Solid >/dev/null 2>&1 && ok "panel theme → Dracula-Solid" \
  || warn "desktop theme failed — try: plasma-apply-desktoptheme Dracula"

# Aurorae is the SVG-based decoration engine; the Dracula theme drawn
# through it has square corners, which Breeze does not expose a setting
# for.
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Dracula"
ok "window decoration → Dracula (square corners)"

kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Dracula-cursors 2>/dev/null && ok "cursor theme"

step "4. Fonts → $FONT_UI"
set_font General font                 "$(font "$FONT_UI"   10)"
set_font General menuFont             "$(font "$FONT_UI"   10)"
set_font General toolBarFont          "$(font "$FONT_UI"    9)"
set_font General smallestReadableFont "$(font "$FONT_UI"    8)"
set_font General fixed                "$(font "$FONT_MONO" 10)"
set_font WM      activeFont           "$(font "$FONT_UI"   10)"
ok "UI, menu, toolbar and titlebar fonts"
ok "fixed-width → $FONT_MONO"

# ── 4. Reload ────────────────────────────────────────────────────────
step "5. Reloading"
dbus-send --session --dest=org.kde.KWin --type=method_call /KWin org.kde.KWin.reconfigure 2>/dev/null \
  && ok "kwin reloaded (decoration + effects)" || warn "could not reach kwin — log out to apply"

printf '\n%sDone.%s\n' "$bold" "$off"
printf '  Colours and decorations are live now.\n'
printf '  %sFonts need a logout%s — Qt reads them once at application start.\n' "$dim" "$off"
printf '  Revert any time with: %s~/dotfiles/kde/apply.sh --revert%s\n' "$dim" "$off"
