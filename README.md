# Matrix-style Wallpaper for KDE Plasma 6

Provides a Matrix-esque "code rainfall" background wallpaper for Plasma 6, with some fun customizations.

![screenshot.png](screenshot.png)

## Features

- Font size and font family picker
- Character sets: Katakana, ASCII, Binary, Braille, pictographs, Runic (any mix)
- Single color, or multi-color with pre-defined palettes
- Background color
- Trail length (min/max per column) and fade step
- Lead highlight (bright white head glyph) and GPU glow
- Drop speed, variable per-column speed, jitter, restart delay
- Direction: down, up, left or right
- Column density and multiple drops per column
- Glitch chance for random bright white characters

## Installation

Installation requires `kpackagetool6`, which is in the `kpackage` package on
Arch based distros, `kpackagetool6` on SUSE based distros, and `kf6-kpackage`
on Debian based distros.

```bash
git clone https://github.com/obsidianreq/matrixrain-plasma6.git
cd matrixrain-plasma6
./install.sh
kquitapp6 plasmashell && kstart plasmashell
```

`install.sh` installs the package, or upgrades it if it is already installed.
To do it by hand instead:

```bash
kpackagetool6 --type Plasma/Wallpaper --install obsidianreq.plasma.wallpaper.matrixrain/
# or, when already installed:
kpackagetool6 --type Plasma/Wallpaper --upgrade obsidianreq.plasma.wallpaper.matrixrain/
```

Then open system settings and there will be a new option under wallpapers.

## Reporting Bugs

if you encounter any issues with the plugin, you can report them on the issue
tracker using the following steps:

- open a terminal and start journalctl with
  `journalctl -f | grep -i --line-buffered matrixrain` this will show logs
  related to the plugin.
- reproduce the issue.
- copy the logs from the terminal and paste them in the issue description.
- describe the issue in detail, and if possible provide steps to reproduce the
  issue.

if the issue cannot be reproduced, you may still open an issue with a
description of the issue and any relevant logs using
`journalctl -b -0 | grep -i matrixrain`, this will show logs related to the
plugin from the current boot.
