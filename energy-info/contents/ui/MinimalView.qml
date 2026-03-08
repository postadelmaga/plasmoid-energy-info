import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: minimalMode
    required property var root

    anchors.margins: 0

    Text {
        id: minWatt
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.55
        text: root.fullWattText
        font.bold: true
        color: root.wattColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        minimumPixelSize: 4
        font.pixelSize: Kirigami.Units.gridUnit * 5
    }

    Item {
        anchors.top: minWatt.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        readonly property real colW: width / 3

        Repeater {
            model: [
                { label: "VOLTS",  value: root.voltageV },
                { label: "AMPS",   value: root.currentA },
                { label: "ESTIM.", value: root.timeRemaining }
            ]
            delegate: Item {
                x: index * parent.colW
                width: parent.colW
                height: parent.height
                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * 0.45
                    text: modelData.label
                    color: Kirigami.Theme.textColor
                    opacity: 0.5
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 4; font.pixelSize: Math.max(8, Kirigami.Units.gridUnit * 1.2)
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * 0.50
                    text: modelData.value
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 4; font.pixelSize: Math.max(8, Kirigami.Units.gridUnit * 2.0)
                }
            }
        }
    }
}
