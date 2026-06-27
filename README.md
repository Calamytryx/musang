# Musang — A Text-Based App Launcher for KDE Plasma

A minimalist, keyboard-driven application launcher widget inspired by **MAKO** (by [rama-io](https://github.com/rama-io/mako))

**Disclaimer:** This project is independent and is not affiliated with the original MAKO project.

## Features

* **Text-based interface** — clean, keyboard-first experience
* **System info at a glance** — clock, date, battery status, and power information
* **Automatic app grouping** — organizes applications using KDE application categories
* **Instant search** — filter apps across all groups in real time
* **Expandable sections** — collapse or expand groups as needed
* **Fully customizable** — colors, fonts, icon, sizing, and appearance
* **Native Plasma integration** — built entirely with KDE Plasma technologies

## Installation

### Install from Source

```bash
git clone https://github.com/calamytryx/musang.git

kpackagetool6 -t Plasma/Applet -i musang
```

Reload Plasma if needed:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

Then add **Musang** from **Add Widgets**.

### Manual Installation

```bash
git clone https://github.com/calamytryx/musang.git \
~/.local/share/plasma/plasmoids/musang
```

## Usage

### Open Launcher

* Click the widget icon
* Search starts immediately
* Press `Escape` to close

### Navigation

* Click group titles → expand/collapse
* Click applications → launch
* Type → search globally

### Configure

Right-click → **Configure Musang**

Customize:

* Icon
* Fonts
* Colors
* Clock and battery display
* Group appearance

## Architecture

* **QML / Qt 6**
* **KDE Plasma Framework**
* **Python indexing and grouping**

## Requirements

* KDE Plasma 6+
* Qt 6+
* Python 3

## Attribution

Based on **MAKO Launcher** by [rama-io](https://github.com/rama-io/mako)

## License

Licensed under **GPL-3.0-or-later**.

See `LICENSE`.

## Contributing

Issues and pull requests are welcome.
