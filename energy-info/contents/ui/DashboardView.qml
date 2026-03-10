import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: dashboardMode
    required property var root

    anchors.fill: parent
    anchors.margins: 0 // Ridotto il margine esterno del dashboard

    // Spessori invertiti: Watt (grande) sottile, Batteria (piccola) grossa
    readonly property real strokeBig: Math.max(2, Math.min(width, height) * 0.025)
    readonly property real strokeSml: Math.max(2, Math.min(width, height) * 0.06)

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing // Ridotto lo spazio tra gauge e barre sotto

        // Riga superiore con i due gauge
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing // Ridotto lo spazio tra i due gauge

            // Gauge WATT (Sinistra)
            Item {
                id: wattGaugeItem
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                Layout.alignment: Qt.AlignCenter

                Canvas {
                    id: canvasGauge
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2;
                        var r = Math.min(width, height) / 2 - dashboardMode.strokeBig / 2 - 1; // Gauge più grande
                        var s = 0.75 * Math.PI, e = 2.25 * Math.PI;
                        ctx.beginPath();
                        ctx.strokeStyle = Kirigami.Theme.disabledTextColor;
                        ctx.lineWidth = dashboardMode.strokeBig; ctx.lineCap = "round";
                        ctx.arc(cx, cy, r, s, e); ctx.stroke();
                        var progress = Math.min(root.currentWatts / 60, 1.0);
                        ctx.beginPath();
                        ctx.strokeStyle = root.wattColor;
                        ctx.lineWidth = dashboardMode.strokeBig; ctx.lineCap = "round";
                        ctx.arc(cx, cy, r, s, s + (e - s) * progress); ctx.stroke();
                    }
                }
                Connections {
                    target: root
                    function onCurrentWattsChanged() { canvasGauge.requestPaint(); }
                }

                Item {
                    id: wattTextBox
                    anchors.centerIn: parent
                    width: parent.width * 0.5
                    height: parent.height * 0.4

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Text {
                            text: root.batteryStatus === "Charging" ? "⚡" : "🔋"
                            color: root.batteryStatus === "Charging" ? root.wattColor : Kirigami.Theme.textColor
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: parent.height * 0.45
                        }

                        Text {
                            text: Math.round(root.currentWatts) + " W"
                            font.bold: true
                            color: root.batteryStatus === "Charging" ? root.wattColor : Kirigami.Theme.textColor
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: parent.height * 0.55
                        }
                    }
                }
            }

            // Gauge BATTERIA (Destra)
            Item {
                id: smallBattGauge
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                Layout.alignment: Qt.AlignCenter

                Canvas {
                    id: canvasBattGauge
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2;
                        var r = Math.min(width, height) / 2 - dashboardMode.strokeSml / 2 - 1; // Gauge più grande
                        var s = 0.75 * Math.PI, e = 2.25 * Math.PI;
                        ctx.beginPath();
                        ctx.strokeStyle = Kirigami.Theme.disabledTextColor;
                        ctx.lineWidth = dashboardMode.strokeSml; ctx.lineCap = "round";
                        ctx.arc(cx, cy, r, s, e); ctx.stroke();
                        var cap = parseFloat(root.batteryCapacity) / 100.0;
                        var bc = cap > 0.5 ? "#50fa7b" : (cap > 0.2 ? "#ffb86c" : "#ff5555");
                        ctx.beginPath();
                        ctx.strokeStyle = bc;
                        ctx.lineWidth = dashboardMode.strokeSml; ctx.lineCap = "round";
                        ctx.arc(cx, cy, r, s, s + (e - s) * cap); ctx.stroke();
                    }
                }
                Connections {
                    target: root
                    function onBatteryCapacityChanged() { canvasBattGauge.requestPaint(); }
                }

                Item {
                    id: battTextBox
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: parent.height * 0.4

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Text {
                            text: root.batteryStatus === "Charging" ? "⚡" : root.timeRemaining
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: parent.height * 0.45
                        }

                        Text {
                            text: root.batteryCapacity
                            font.bold: true
                            color: Kirigami.Theme.textColor
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: parent.height * 0.55
                        }
                    }
                }
            }
        }

        // Barre di dettaglio (Sotto)
        ColumnLayout {
            id: bottomBars
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { value: root.voltageV,          progress: root.voltageVRaw / 12.0,   color: "#00FFFF" },
                    { value: root.currentA,          progress: root.currentARaw / 5.0,    color: "#FFFF00" },
                    { value: "💓 " + root.batteryHealth, progress: (parseFloat(root.batteryHealth) || 0) / 100.0, color: "#FF1493" }
                ]
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        color: "#000000"
                        opacity: 0.2
                        radius: 4
                        
                        Rectangle {
                            width: parent.width * Math.min(1.0, Math.max(0, modelData.progress))
                            height: parent.height
                            color: modelData.color
                            radius: 4
                        }
                    }

                    Text {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        text: modelData.value
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Units.gridUnit * 0.75
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                    }
                }
            }
        }
    }
}
