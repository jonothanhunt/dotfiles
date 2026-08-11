<#
.SYNOPSIS
  Applies the Gruvbox palette and JetBrainsMono Nerd Font to
  Windows Terminal, so the Windows side matches what install.sh sets up
  inside WSL.

.DESCRIPTION
  Run this in PowerShell on the *Windows* side, not inside WSL:

      .\windows\apply.ps1
      .\windows\apply.ps1 -DryRun     # show what would happen

  It does three things, each skippable if already done:

    1. Installs JetBrainsMono Nerd Font for the current user. No admin
       needed — per-user fonts live under LOCALAPPDATA and are registered
       in HKCU rather than the machine-wide store.
    2. Merges gruvbox.json into Windows Terminal's settings.json
       schemes list, backing the file up first.
    3. Points the default profile at that scheme and font.

  Nothing here is destructive: settings.json is copied to
  settings.json.bak-<timestamp> before it is touched.
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$schemeName = 'Gruvbox Dark Hard'
$fontName = 'JetBrainsMono Nerd Font'

function Say  ($m) { Write-Host $m }
function Ok   ($m) { Write-Host "  [ok]   $m" -ForegroundColor Green }
function Skip ($m) { Write-Host "  [skip] $m" -ForegroundColor DarkGray }
function Warn ($m) { Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "  [fail] $m" -ForegroundColor Red; exit 1 }

if ($DryRun) { Say "DRY RUN - nothing will be changed" }

# ── 1. Font ──────────────────────────────────────────────────────────
# Windows Terminal draws the powerline glyphs itself, reading the Windows
# font store. A font installed inside WSL is invisible to it, which is
# why this step exists separately from install.sh at all.
Say ""
Say "1. Font"

$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$installed = @(Get-ChildItem -Path $fontDir -Filter 'JetBrainsMonoNerdFont*.ttf' -ErrorAction SilentlyContinue)

if ($installed.Count -gt 0) {
    Skip "$fontName already installed ($($installed.Count) files)"
} elseif ($DryRun) {
    Say "  would: download and install $fontName into $fontDir"
} else {
    $tmp = Join-Path $env:TEMP "jbmono-$stamp"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        # Resolve the latest release the same way install.sh does, so both
        # sides land on the same version rather than drifting apart.
        $url = $null
        try {
            $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' -Headers @{ 'User-Agent' = 'dotfiles' }
            $url = ($rel.assets | Where-Object { $_.name -eq 'JetBrainsMono.zip' } | Select-Object -First 1).browser_download_url
        } catch {
            Warn "could not query GitHub for the latest release, falling back to a pinned version"
        }
        if (-not $url) { $url = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/JetBrainsMono.zip' }

        $zip = Join-Path $tmp 'JetBrainsMono.zip'
        Invoke-WebRequest -Uri $url -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $tmp -Force

        New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
        # Only the Mono variant, matching font-family in ghostty/config:
        # strict single-width cells keep the tmux status bar aligned.
        $ttfs = Get-ChildItem -Path $tmp -Filter 'JetBrainsMonoNerdFontMono-*.ttf' -Recurse
        if ($ttfs.Count -eq 0) { $ttfs = Get-ChildItem -Path $tmp -Filter '*.ttf' -Recurse }

        $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        foreach ($f in $ttfs) {
            $dest = Join-Path $fontDir $f.Name
            Copy-Item -Path $f.FullName -Destination $dest -Force
            # Per-user font registration wants the full path as the value;
            # the machine-wide store is the one that takes a bare filename.
            Set-ItemProperty -Path $regPath -Name "$($f.BaseName) (TrueType)" -Value $dest
        }
        Ok "$fontName installed ($($ttfs.Count) files) - restart Windows Terminal to see it"
    } finally {
        Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ── 2. Windows Terminal settings ─────────────────────────────────────
Say ""
Say "2. Windows Terminal"

$candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
$settingsPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $settingsPath) {
    Warn "Windows Terminal settings.json not found - is it installed?"
    Warn "  looked in:"
    $candidates | ForEach-Object { Warn "    $_" }
    exit 0
}
Ok "found $settingsPath"

$schemeFile = Join-Path $PSScriptRoot 'gruvbox.json'
if (-not (Test-Path $schemeFile)) { Fail "missing $schemeFile" }
$scheme = Get-Content -Raw -Path $schemeFile | ConvertFrom-Json

# settings.json is JSONC - Windows Terminal ships it full of // comments,
# and ConvertFrom-Json rejects those. Rather than risk mangling the file
# with a regex that cannot tell a comment from the // inside an https://
# URL, parse it honestly and bail out with instructions if it will not.
$raw = Get-Content -Raw -Path $settingsPath
try {
    $settings = $raw | ConvertFrom-Json
} catch {
    Warn "settings.json has comments or is otherwise not plain JSON, so it was left untouched."
    Warn "Add the scheme by hand instead:"
    Warn "  1. Windows Terminal > Settings > 'Open JSON file'"
    Warn "  2. paste the contents of windows/gruvbox.json into the `"schemes`" array"
    Warn "  3. set `"colorScheme`": `"$schemeName`" in profiles.defaults"
    exit 0
}

if ($DryRun) {
    Say "  would: back up settings.json and add the '$schemeName' scheme"
    Say "  would: set profiles.defaults colorScheme + font to '$schemeName' / '$fontName'"
    Say ""
    Say "Dry run complete."
    exit 0
}

$backup = "$settingsPath.bak-$stamp"
Copy-Item -Path $settingsPath -Destination $backup -Force
Ok "backed up to $(Split-Path -Leaf $backup)"

if (-not $settings.schemes) {
    $settings | Add-Member -NotePropertyName schemes -NotePropertyValue @() -Force
}
# Replace an existing copy rather than appending a duplicate, so this is
# safe to re-run after editing the palette.
$others = @($settings.schemes | Where-Object { $_.name -ne $schemeName })
$settings.schemes = @($others + $scheme)
Ok "scheme '$schemeName' merged ($($settings.schemes.Count) schemes total)"

if (-not $settings.profiles) {
    $settings | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) -Force
}
if (-not $settings.profiles.defaults) {
    $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
}
$settings.profiles.defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue $schemeName -Force
$settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = $fontName }) -Force
Ok "profiles.defaults -> colorScheme '$schemeName', font '$fontName'"

# Depth matters: the default of 2 silently flattens nested objects into
# type names, which would quietly destroy the settings file.
$settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding UTF8
Ok "settings.json written"

Say ""
Say "Done. Restart Windows Terminal."
Say "  If anything looks wrong, restore with:"
Say "    Copy-Item '$backup' '$settingsPath' -Force"
