import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Kirigami.FormLayout {
    property alias cfg_viewMode: viewModeCombo.currentIndex

    Controls.ComboBox {
        id: viewModeCombo
        Kirigami.FormData.label: i18n("Visualization Mode:")
        model: [
            i18n("Dashboard (Gauge)"),
            i18n("Analytics (Big Graph)"),
            i18n("Data Grid (Minimal)")
        ]
    }
}
