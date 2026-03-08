import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: dashboardMode
    required property var root

    anchors.margins: 0

    readonly property real smallW:    width * 0.32
    readonly property real gap:       width * 0.04
    readonly property real strokeBig: Math.max(2, Math.min(width, height) * 0.04)
    readonly property real strokeSml: Math.max(2, smallW * 0.04)

    // Gauge WATT — grande, a sinistra
    Item {
        id: wattGaugeItem
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        width: parent.width - dashboardMode.smallW - dashboardMode.gap

        Canvas {
            id: canvasGauge
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var r = Math.min(width, height) / 2 - dashboardMode.strokeBig - 2;
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
        Connections {
            target: dashboardMode
            function onStrokeBigChanged() { canvasGauge.requestPaint(); }
        }

        // Testo centrato nel gauge
        Item {
            id: wattTextBox
            anchors.centerIn: parent
            width:  parent.width  * 0.52
            height: parent.height * 0.44

            Text {
                id: wattNum
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.55
                text: (root.batteryStatus === "Charging" ? "+" : "") + Math.round(root.currentWatts)
                font.bold: true
                color: root.batteryStatus === "Charging" ? root.wattColor : Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.pixelSize: 999
            }
            Text {
                anchors.top: wattNum.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.22
                text: "WATT"
                color: Kirigami.Theme.textColor
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.pixelSize: 999
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.20
                text: root.voltageV + " • " + root.currentA
                color: Kirigami.Theme.textColor
                opacity: 0.4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.pixelSize: 999
            }
        }
    }

    // Gauge BATTERIA — proporzionale, a destra, centrato verticalmente
    Item {
        id: smallBattGauge
        width:  dashboardMode.smallW
        height: dashboardMode.smallW
        anchors.right:          parent.right
        anchors.verticalCenter: wattGaugeItem.verticalCenter

        Canvas {
            id: canvasBattGauge
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var r = Math.min(width, height) / 2 - dashboardMode.strokeSml - 2;
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
        Connections {
            target: dashboardMode
            function onStrokeSmlChanged() { canvasBattGauge.requestPaint(); }
        }

        Item {
            id: battTextBox
            anchors.centerIn: parent
            width:  parent.width  * 0.58
            height: parent.height * 0.36

            Text {
                id: battPct
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.62
                text: root.batteryCapacity
                font.bold: true
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.pixelSize: 999
            }
            Text {
                anchors.top: battPct.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: root.batteryStatus === "Charging" ? "⚡" : root.timeRemaining
                color: Kirigami.Theme.textColor
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.pixelSize: 999
            }
        }
    }
}
