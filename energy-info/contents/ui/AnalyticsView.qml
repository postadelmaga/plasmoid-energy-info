import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: analyticsMode
    required property var root

    anchors.margins: 0

    // Header Overlay
    Text {
        id: analyticsHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.12
        text: root.fullWattText + "  •  " + root.batteryCapacity + "  •  " + root.timeRemaining
        font.bold: true
        color: Kirigami.Theme.textColor
        opacity: 0.7
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        minimumPixelSize: 4
        font.pixelSize: Math.max(10, Kirigami.Units.gridUnit * 1.5)
        elide: Text.ElideRight
    }

    Canvas {
        id: canvasBigSparkline
        anchors.top: analyticsHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.largeSpacing
        onPaint: {
            try {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (root.history.length < 2) return;
                
                // Grid lines
                ctx.beginPath();
                ctx.setLineDash([4, 4]);
                ctx.strokeStyle = String(Kirigami.Theme.disabledTextColor);
                ctx.globalAlpha = 0.15;
                for (var j = 1; j < 5; j++) {
                    var gy = (height / 5) * j;
                    ctx.moveTo(0, gy); ctx.lineTo(width, gy);
                }
                ctx.stroke();
                ctx.setLineDash([]); 
                ctx.globalAlpha = 1.0;

                var pts = [];
                var xStep = width / (root.maxHistory - 1);
                var maxGraphVal = 60; // Max wattage for scale

                for (var i = 0; i < root.history.length; i++) {
                    var val = Math.min(root.history[i], maxGraphVal);
                    pts.push({ x: i * xStep, y: height - (val / maxGraphVal * height) });
                }

                // Smooth Bezier Curve Path
                ctx.beginPath();
                ctx.strokeStyle = String(root.wattColor);
                ctx.lineWidth = Math.max(2, height * 0.02);
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.moveTo(pts[0].x, pts[0].y);
                
                for (var k = 1; k < pts.length; k++) {
                    var cp1x = pts[k-1].x + (pts[k].x - pts[k-1].x) / 2;
                    var cp1y = pts[k-1].y;
                    var cp2x = pts[k-1].x + (pts[k].x - pts[k-1].x) / 2;
                    var cp2y = pts[k].y;
                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, pts[k].x, pts[k].y);
                }
                ctx.stroke();

                // Gradient Fill under curve
                ctx.lineTo(pts[pts.length-1].x, height);
                ctx.lineTo(pts[0].x, height);
                ctx.closePath();
                
                var gradient = ctx.createLinearGradient(0, 0, 0, height);
                gradient.addColorStop(0, String(root.wattColor));
                gradient.addColorStop(1, "transparent");
                ctx.fillStyle = gradient;
                ctx.globalAlpha = 0.25;
                ctx.fill();
                ctx.globalAlpha = 1.0;

                // Active Data Point Circle (End of the line)
                var lastPt = pts[pts.length-1];
                ctx.beginPath();
                ctx.fillStyle = String(Kirigami.Theme.backgroundColor);
                ctx.arc(lastPt.x, lastPt.y, ctx.lineWidth * 2.0, 0, 2 * Math.PI);
                ctx.fill();
                ctx.beginPath();
                ctx.fillStyle = String(root.wattColor);
                ctx.arc(lastPt.x, lastPt.y, ctx.lineWidth * 1.2, 0, 2 * Math.PI);
                ctx.fill();
            } catch (err) {
                console.log("Canvas Error: " + err);
            }
        }
    }
    
    Connections {
        target: root
        function onHistoryChanged() { canvasBigSparkline.requestPaint(); }
    }
}
