import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property var self: root
    
    // Core data properties
    property double currentWatts: 0.0
    property string wattText: "--W"
    property string fullWattText: "-- W"
    property color wattColor: Kirigami.Theme.textColor
    
    // Granular details
    property string batteryCapacity: "--"
    property string batteryStatus: "--"
    property double voltageVRaw: 0.0  // Numeric value in Volts
    property double currentARaw: 0.0  // Numeric value in Amperes
    property string voltageV: "-- V"  // Display string with unit
    property string currentA: "-- A"  // Display string with unit
    property string batteryHealth: "--"

    // History for Sparkline
    property var history: []
    readonly property int maxHistory: 30

    // Configuration property
    readonly property int viewMode: plasmoid.configuration.viewMode

    // New detailed properties
    property string timeRemaining: "--"
    
    // Tracking flags
    property bool healthCalculated: false
    property double healthChargeFull: 0.0 // Cache for ch_full during health calculation

    // Tooltip
    toolTipMainText: i18n("Power Consumption")
    toolTipSubText: root.fullWattText

    // DataSource per letture rapide (ogni 2 secondi)
    Plasma5Support.DataSource {
        id: executablePower
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let cap = data.stdout.trim();
            if (cap && cap !== "") {
                root.batteryCapacity = cap + "%";
            }
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableStatus
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let stat = data.stdout.trim();
            if (stat && stat !== "") {
                root.batteryStatus = stat;
            }
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableVoltage
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let v_raw = parseFloat(data.stdout.trim()) || 0;
            root.voltageVRaw = v_raw / 10**6;  // Convert μV to V
            root.voltageV = root.voltageVRaw.toFixed(2) + " V";
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableCurrent
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let c_raw = parseFloat(data.stdout.trim()) || 0;
            
            // Use 1A as fixed value when current is 0
            let c_display = c_raw === 0 ? 1000000 : c_raw;  // 1A = 1000000 μA
            
            root.currentARaw = c_display / 10**6;  // Convert μA to A (1.0 if c_raw was 0)
            root.currentA = root.currentARaw.toFixed(2) + " A";
            
            // Update wattage calculation using the display current
            // voltageVRaw is in V, c_display is in µA, so: V × µA / 10^6 = W
            let val = (root.voltageVRaw * c_display) / 10**6;
            let prefix = (root.batteryStatus === "Charging") ? "+" : "";
            root.currentWatts = isNaN(val) ? 0.0 : val;
            root.wattText = prefix + Math.round(root.currentWatts) + "W";
            root.fullWattText = prefix + root.currentWatts.toFixed(2) + " W";

            // Update color
            if (root.batteryStatus === "Charging") root.wattColor = "#8be9fd"; // Cyan for charging
            else if (val > 25) root.wattColor = "#ff5555";
            else if (val > 15) root.wattColor = "#ffb86c";
            else root.wattColor = "#50fa7b";

            // Update history for sparkline
            let newHistory = root.history.slice();
            newHistory.push(root.currentWatts);
            if (newHistory.length > root.maxHistory) newHistory.shift();
            root.history = newHistory;

            // Time estimation (use original c_raw for accurate time calculation)
            if (c_raw > 0) {
                let ch_now = parseFloat(executableChargeNow.connectedSources[0]) || 0;
                let ch_full = parseFloat(executableChargeFull.connectedSources[0]) || 0;
                let hours = (root.batteryStatus === "Charging") ? (ch_full - ch_now) / c_raw : ch_now / c_raw;
                let h = Math.floor(hours);
                let m = Math.floor((hours - h) * 60);
                root.timeRemaining = (h > 0 ? h + "h " : "") + m + "m";
            } else {
                root.timeRemaining = "--";
            }
            
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableChargeNow
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableChargeFull
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    // Health check - once at startup and then every 60 seconds
    Plasma5Support.DataSource {
        id: executableHealth
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            root.healthChargeFull = parseFloat(data.stdout.trim()) || 0;
            executableHealthDesign.connectSource("cat /sys/class/power_supply/BAT0/charge_full_design");
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executableHealthDesign
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let ch_design = parseFloat(data.stdout.trim()) || 0;
            if (ch_design > 0 && root.healthChargeFull > 0) {
                let health = (root.healthChargeFull / ch_design) * 100;
                root.batteryHealth = health.toFixed(1) + "%";
                root.healthCalculated = true;
            }
            disconnectSource(source);
        }
    }

    Timer {
        id: timerPower
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executablePower.connectSource("cat /sys/class/power_supply/BAT0/capacity");
            executableStatus.connectSource("cat /sys/class/power_supply/BAT0/status");
            executableVoltage.connectSource("cat /sys/class/power_supply/BAT0/voltage_now");
            executableCurrent.connectSource("cat /sys/class/power_supply/BAT0/current_now");
            executableChargeNow.connectSource("cat /sys/class/power_supply/BAT0/charge_now");
            executableChargeFull.connectSource("cat /sys/class/power_supply/BAT0/charge_full");
        }
    }

    Timer {
        id: timerHealth
        interval: 60000  // 60 seconds for health check
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executableHealth.connectSource("cat /sys/class/power_supply/BAT0/charge_full");
        }
    }

    compactRepresentation: MouseArea {
        id: compactRoot
        readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        
        Layout.minimumWidth: isVertical ? 0 : contentRow.implicitWidth
        Layout.minimumHeight: isVertical ? contentRow.implicitHeight : 0
        implicitWidth: Layout.minimumWidth
        implicitHeight: Layout.implicitHeight

        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        GridLayout {
            id: contentRow
            anchors.centerIn: parent
            columns: isVertical ? 1 : 2
            rowSpacing: 0
            columnSpacing: 2

            Kirigami.Icon {
                source: "battery-charging"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.alignment: Qt.AlignCenter
            }

            PlasmaComponents.Label {
                text: root.wattText
                color: root.wattColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize 
                font.bold: true
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        
        Layout.preferredWidth:  root.viewMode === 1 ? Kirigami.Units.gridUnit * 18
                               : root.viewMode === 2 ? Kirigami.Units.gridUnit * 12
                               : Kirigami.Units.gridUnit * 18
                              
        Layout.preferredHeight: root.viewMode === 1 ? Kirigami.Units.gridUnit * 12
                                : root.viewMode === 2 ? Kirigami.Units.gridUnit * 6
                                : Kirigami.Units.gridUnit * 12

        Loader {
            id: viewLoader
            anchors.fill: parent

            function updateSource() {
                let s = "";
                if (root.viewMode === 0) s = "DashboardView.qml";
                else if (root.viewMode === 1) s = "AnalyticsView.qml";
                else if (root.viewMode === 2) s = "MinimalView.qml";
                
                if (s !== "") {
                    setSource(s, { "root": root.self });
                } else {
                    source = "";
                }
            }

            Component.onCompleted: updateSource()

            Connections {
                target: root
                function onViewModeChanged() {
                    viewLoader.updateSource();
                }
            }
        }
    }
}
