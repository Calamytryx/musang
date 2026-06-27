# Musang — A Text-Based App Launcher for KDE Plasma

A minimalist, keyboard-driven application launcher widget inspired by **MAKO** (by [rama-io](https://github.com/rama-io/mako)) — brought to KDE Plasma.

## Features

- **Text-based interface** — clean, distraction-free design
- **System info at a glance** — clock, date, battery status, charge/discharge rate
- **Smart app organization** — groups apps automatically from KDE's `.directory` files
- **Instant search** — type to filter across all categories
- **Expandable groups** — collapse/expand categories on demand
- **Fully customizable** — colors, fonts, sizes, background
- **Zero dependencies** — pure KDE Plasma technology

## Installation

### From Source

```bash
git clone https://github.com/calamytryx/musang.git
cd musang
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r musang ~/.local/share/plasma/plasmoids/musang
```

Then add the widget to your panel or desktop.

### Via KDE Store

(Link coming soon)

## Usage

### Opening the Launcher
- Click the widget icon in your panel
- Search box auto-focuses — start typing immediately
- Press `Escape` to close

### Navigation
- **Click group names** — expand/collapse categories
- **Click apps** — launch instantly
- **Search** — type app name to filter across all groups

### Customization

Right-click the widget → **Configure**:
- Icon, fonts, colors
- Clock/date/battery display
- Group styling

### App Organization

Apps are organized using KDE's `.directory` files in `~/.local/share/desktop-directories/`:

```
~/.local/share/desktop-directories/
├── kf5-development.directory      → Development apps
├── kf5-games.directory            → Games
├── kf5-internet.directory         → Internet & networking
├── kf5-multimedia.directory       → Audio, video, music
├── kf5-office.directory           → Office apps
├── kf5-utilities.directory        → Utilities
└── ... (customize by creating/editing .directory files)
```

To add a custom group, create a `.directory` file:
```ini
[Desktop Entry]
Name=My Custom Group
Icon=applications-custom
Type=Directory
```

## Architecture

- **QML/Qt 6** — responsive, theme-integrated UI
- **Python scanning** — intelligent app categorization
- **KDE Plasma integration** — native configuration, theming

## Requirements

- KDE Plasma 6.x
- Qt 6.x
- Python 3.x

## Attributions

Based on **MAKO Launcher** by [rama-io](https://github.com/rama-io/mako)

Licensed under the same terms as the original MAKO.

## License

[Same as MAKO — check original project]

## Contributing

Bug reports and suggestions welcome! Open an issue or reach out.

---

**Built with ❤️ for KDE Plasma**
