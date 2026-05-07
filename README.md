# Matrix-style Wallpaper for KDE Plasma 6

Provides a Matrix-esque "code rainfall" background wallpaper for Plasma 6, with some fun custommizations.

![screenshot.png](screenshot.png)

## Features

- Change font size
- Choose between single color, or multi-color with pre-defined palettes
- Customize drop speed
- Jitter effect
- Glitch chance for a random bright white characters

## Installation

installation requires `kpackagetool6` which can be found on the `kpackage`
package on arch based distros, `kpackagetool6` on Suse based distros, and
`kf6-kpackage` on debian based distros.

```bash
git clone https://github.com/obsidianreq/matrixrain-plasma6.git
cd matrixrain-plasma6
kpackagetool6 --type Plasma/Wallpaper --install obsidianreq.plasma.wallpaper.matrixrain/
kquitapp6 plasmashell && kstart plasmashell
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
