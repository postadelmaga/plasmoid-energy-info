# Energy Info Widget - Agent Guidelines

## Project Overview
KDE Plasma 6 widget (plasmoid) for monitoring system power consumption (wattage, voltage, current) via `/sys/class/power_supply/`.

## Build Commands

```bash
# Build the .plasmoid package
./build.sh

# Manual build (creates distributable package)
zip -r energy-info.plasmoid energy-info/ -x "energy-info/.git/*"
```

## Testing Commands

```bash
# Test with plasmawindowed (requires plasma SDK)
plasmawindowed -d energy-info/

# Note: The code is symlinked to the installation directory, so changes are reflected automatically.

# Refresh for testing
kbuildsycoca6  # Refresh KDE cache
plasmashell --replace &  # Restart Plasma

# Check for QML errors
timeout 5 plasmawindowed -d energy-info/ 2>&1 | grep -i "error\|qml"
```

## Code Style Guidelines

### QML (UI Files)
- **Imports**: Group Qt imports first, then KDE imports
  ```qml
  import QtQuick
  import QtQuick.Layouts
  import org.kde.plasma.plasmoid
  import org.kde.plasma.core as PlasmaCore
  import org.kde.plasma.components as PlasmaComponents
  import org.kde.plasma.plasma5support as Plasma5Support
  import org.kde.kirigami as Kirigami
  ```
- **Indentation**: 4 spaces
- **Id naming**: camelCase (e.g., `root`, `viewLoader`, `executable`)
- **Property aliases**: Use `cfg_` prefix for config bindings in `configGeneral.qml`.
- **Strings**: Use `i18n()` for all user-facing strings.
- **Comments**: Italian allowed for implementation notes, English preferred for structure.

### Data Collection (Bash/DataSource)
- Data is collected using `Plasma5Support.DataSource` with the `executable` engine.
- Sources: `/sys/class/power_supply/BAT0/` (capacity, status, voltage_now, current_now, charge_now, charge_full).

### File Structure
```
energy-info/
├── metadata.json              # Widget metadata (org.plasmoid.energy-info)
├── contents/
│   ├── ui/
│   │   ├── main.qml          # Main widget entry point
│   │   ├── DashboardView.qml # Gauge and graph view
│   │   ├── AnalyticsView.qml # Detailed analytics view
│   │   ├── MinimalView.qml   # Compact grid view
│   │   └── configGeneral.qml # Settings page
│   └── config/
│       ├── main.xml          # Config schema
│       └── config.qml        # Config page organization
```

## UI Patterns

- Use `Kirigami.Theme` for colors.
- Use `Kirigami.Units` for spacing.
- Support both compact (panel) and full (popup) representations.
- The widget uses a `Loader` to switch between different views (`Dashboard`, `Analytics`, `Minimal`).

## Plasma 6 Specifics

- Root element must be `PlasmoidItem`.
- Minimum API version: `"X-Plasma-API-Minimum-Version": "6.0"`.

## CI/CD

GitHub Actions workflow:
- Triggers on push and tags.
- Runs `build.sh` to create `energy-info.plasmoid`.
- Uploads artifact and creates releases for tags.

## References

- `.agents/skills/kde-plasma-widget-dev/SKILL.md` - Comprehensive Plasma 6 development guide.
- KDE Developer Docs: https://develop.kde.org/docs/plasma/widget/
