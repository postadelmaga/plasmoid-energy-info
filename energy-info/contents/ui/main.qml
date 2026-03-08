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
    property string voltageV: "-- V"
    property string currentA: "-- A"

    // History for Sparkline
    property var history: []
    readonly property int maxHistory: 30

    // Configuration property
    readonly property int viewMode: plasmoid.configuration.viewMode

    // New detailed properties
    property string timeRemaining: "--"

    // Tooltip
    toolTipMainText: i18n("Power Consumption")
    toolTipSubText: root.fullWattText

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            let output = data.stdout.trim().split(" ");
            if (output.length >= 6) {
                let cap = output[0];
                let stat = output[1];
                let v_raw = parseFloat(output[2]);
                let c_raw = parseFloat(output[3]);
                let ch_now = parseFloat(output[4]);
                let ch_full = parseFloat(output[5]);
                
                let val = (v_raw * c_raw) / 10**12;
                let prefix = (stat === "Charging") ? "+" : "";
                root.currentWatts = val;
                root.wattText = prefix + Math.round(val) + "W";
                root.fullWattText = prefix + val.toFixed(2) + " W";
                
                root.batteryCapacity = cap + "%";
                root.batteryStatus = stat;
                root.voltageV = (v_raw / 10**6).toFixed(2) + " V";
                root.currentA = (c_raw / 10**6).toFixed(2) + " A";

                // Time estimation
                if (c_raw > 0) {
                    let hours = (stat === "Charging") ? (ch_full - ch_now) / c_raw : ch_now / c_raw;
                    let h = Math.floor(hours);
                    let m = Math.floor((hours - h) * 60);
                    root.timeRemaining = (h > 0 ? h + "h " : "") + m + "m";
                } else {
                    root.timeRemaining = "--";
                }

                // Update color
                if (stat === "Charging") root.wattColor = "#8be9fd"; // Cyan for charging
                else if (val > 25) root.wattColor = "#ff5555";
                else if (val > 15) root.wattColor = "#ffb86c";
                else root.wattColor = "#50fa7b";

                // Update history for sparkline
                let newHistory = root.history.slice();
                newHistory.push(val);
                if (newHistory.length > root.maxHistory) newHistory.shift();
                root.history = newHistory;
            }
            disconnectSource(source);
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executable.connectSource("awk 'BEGIN {getline cap < \"/sys/class/power_supply/BAT0/capacity\"; getline stat < \"/sys/class/power_supply/BAT0/status\"; getline v < \"/sys/class/power_supply/BAT0/voltage_now\"; getline c < \"/sys/class/power_supply/BAT0/current_now\"; getline ch_now < \"/sys/class/power_supply/BAT0/charge_now\"; getline ch_full < \"/sys/class/power_supply/BAT0/charge_full\"; print cap, stat, v, c, ch_now, ch_full}'");
        }
    }

    compactRepresentation: MouseArea {
        id: compactRoot
        readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        
        Layout.minimumWidth: isVertical ? 0 : contentRow.implicitWidth
        Layout.minimumHeight: isVertical ? contentRow.implicitHeight : 0
        implicitWidth: Layout.minimumWidth
        implicitHeight: Layout.minimumHeight

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
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 1
                font.bold: true
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        
        Layout.preferredWidth:  root.viewMode === 1 ? Kirigami.Units.gridUnit * 18
                              : root.viewMode === 2 ? Kirigami.Units.gridUnit * 12
                              : Kirigami.Units.gridUnit * 16
                              
        Layout.preferredHeight: root.viewMode === 1 ? Kirigami.Units.gridUnit * 12
                               : root.viewMode === 2 ? Kirigami.Units.gridUnit * 6
                               : Kirigami.Units.gridUnit * 8

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
