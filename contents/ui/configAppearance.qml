import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC
import org.kde.iconthemes 1.0 as KIconThemes

QQC2.ScrollView {
    clip: true
    contentWidth: availableWidth

    // ── Config properties ────────────────────────────────────────────────────
    property string cfg_plasmoidIcon
    property string cfg_powerGroupName
    property string cfg_globalFontFamily
    property bool   cfg_showPlasmaBackground
    property string cfg_widgetBackgroundColor

    property real   cfg_clockFontSize
    property string cfg_clockFontColor

    property real   cfg_dateFontSize
    property string cfg_dateFontColor

    property real   cfg_batteryFontSize
    property string cfg_batteryFontColor

    property real   cfg_groupHeaderFontSize
    property string cfg_groupHeaderFontColor
    property string cfg_groupHeaderBackgroundColor

    property real   cfg_groupItemFontSize
    property string cfg_groupItemFontColor
    property string cfg_groupItemBackgroundColor

    property real   cfg_searchFontSize
    property string cfg_searchFontColor
    property string cfg_searchBackgroundColor

    Kirigami.FormLayout {
        id: page
        implicitWidth: parent.width

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        // ── Helper: integer spin that represents one decimal place ────────────
        component DecimalSizeSpinBox: QQC2.SpinBox {
            from: 5; to: 150; stepSize: 1
            textFromValue: function(v) { return (v / 10).toFixed(1) }
            valueFromText: function(t) { return Math.round(parseFloat(t) * 10) }
        }

        // ── Helper: colour button + clear + label ─────────────────────────────
        component ColorPicker: RowLayout {
            id: cp
            property string colorValue: ""
            signal committed(string newColor)

            spacing: Kirigami.Units.smallSpacing

            KQC.ColorButton {
                color:            cp.colorValue.length > 0 ? cp.colorValue : "transparent"
                showAlphaChannel: false
                onAccepted: {
                    cp.colorValue = color.toString()
                    cp.committed(cp.colorValue)
                }
            }
            QQC2.Button {
                text:    "Clear"
                visible: cp.colorValue.length > 0
                onClicked: {
                    cp.colorValue = ""
                    cp.committed("")
                }
            }
            QQC2.Label {
                text:           cp.colorValue.length > 0 ? cp.colorValue : "(theme default)"
                opacity:        0.6
                font.pixelSize: Kirigami.Units.gridUnit * 0.85
            }
        }

        // ── Font dialog ───────────────────────────────────────────────────────
        FontDialog {
            id: fontDialog
            onAccepted: cfg_globalFontFamily = selectedFont.family
        }

        // ════════════════════════════════════════════════════════════════════
        // General
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "General"
        }

        // Widget icon — button shows current icon, click opens KDE icon browser.
        // Uses KIconThemes.IconDialog (org.kde.iconthemes 1.0) — the only approach
        // confirmed to work at runtime. Dialog lives inside the button item.
        QQC2.Button {
            id: iconButton
            Kirigami.FormData.label: "Widget icon:"

            // Derive display icon directly from cfg — no separate tracking property
            // needed, so no illegal onCfg_* handler inside a child item.
            readonly property string displayIcon: cfg_plasmoidIcon.length > 0
            ? cfg_plasmoidIcon
            : Qt.resolvedUrl("../../musang.png").toString().replace("file://", "")

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source:         iconButton.displayIcon
                    implicitWidth:  Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                }
                QQC2.Label {
                    text:           iconButton.displayIcon
                    opacity:        0.7
                    font.pixelSize: Kirigami.Units.gridUnit * 0.85
                }
            }

            onClicked: iconDialog.open()

            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: {
                    if (iconName && iconName.length > 0) {
                        cfg_plasmoidIcon = iconName
                    }
                }
            }

            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text:    iconButton.displayIcon
            QQC2.ToolTip.delay:   Kirigami.Units.toolTipDelay
        }

        // Reset icon sits outside the button so it's a sibling in the form row
        QQC2.Button {
            Kirigami.FormData.label: ""
            text:    "Reset icon"
            visible: cfg_plasmoidIcon.length > 0
            onClicked: {
                cfg_plasmoidIcon = ""
                iconButton.currentIcon = Qt.resolvedUrl("../../musang.png").toString().replace("file://", "")
            }
        }

        // Power group name
        QQC2.TextField {
            Kirigami.FormData.label: "Power Group Name:"
            text:            cfg_powerGroupName
            placeholderText: "e.g. Power, Session Controls"
            onTextEdited:    cfg_powerGroupName = text
        }

        // Global font
        RowLayout {
            Kirigami.FormData.label: "Global font:"
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text:        cfg_globalFontFamily.length > 0 ? cfg_globalFontFamily : "Sans Serif"
                font.family: cfg_globalFontFamily.length > 0 ? cfg_globalFontFamily : "Sans Serif"
                onClicked: {
                    fontDialog.selectedFont = Qt.font({ family: cfg_globalFontFamily })
                    fontDialog.open()
                }
            }
            QQC2.Button {
                text:    "Reset"
                visible: cfg_globalFontFamily.length > 0
                onClicked: cfg_globalFontFamily = ""
            }
        }

        // Plasma background
        QQC2.CheckBox {
            Kirigami.FormData.label: "Plasma background:"
            text:             "Show Plasma's own panel/popup background"
            checked:          cfg_showPlasmaBackground
            onCheckedChanged: cfg_showPlasmaBackground = checked
        }

        // Widget background colour
        ColorPicker {
            Kirigami.FormData.label: "Launcher background:"
            colorValue: cfg_widgetBackgroundColor
            onCommitted: (c) => cfg_widgetBackgroundColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // Clock
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "Clock"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_clockFontSize * 10)
            onValueModified: cfg_clockFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_clockFontColor
            onCommitted: (c) => cfg_clockFontColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // Date line
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "Date line"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_dateFontSize * 10)
            onValueModified: cfg_dateFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_dateFontColor
            onCommitted: (c) => cfg_dateFontColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // Battery line
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "Battery line"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_batteryFontSize * 10)
            onValueModified: cfg_batteryFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_batteryFontColor
            onCommitted: (c) => cfg_batteryFontColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // Group headers
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "Group headers"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_groupHeaderFontSize * 10)
            onValueModified: cfg_groupHeaderFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_groupHeaderFontColor
            onCommitted: (c) => cfg_groupHeaderFontColor = c
        }
        ColorPicker {
            Kirigami.FormData.label: "Background:"
            colorValue: cfg_groupHeaderBackgroundColor
            onCommitted: (c) => cfg_groupHeaderBackgroundColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // App / subgroup items
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "App / subgroup items"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_groupItemFontSize * 10)
            onValueModified: cfg_groupItemFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_groupItemFontColor
            onCommitted: (c) => cfg_groupItemFontColor = c
        }
        ColorPicker {
            Kirigami.FormData.label: "Background:"
            colorValue: cfg_groupItemBackgroundColor
            onCommitted: (c) => cfg_groupItemBackgroundColor = c
        }

        // ════════════════════════════════════════════════════════════════════
        // Search box
        // ════════════════════════════════════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:    "Search box"
        }

        DecimalSizeSpinBox {
            Kirigami.FormData.label: "Font size:"
            value:           Math.round(cfg_searchFontSize * 10)
            onValueModified: cfg_searchFontSize = value / 10
        }
        ColorPicker {
            Kirigami.FormData.label: "Font color:"
            colorValue: cfg_searchFontColor
            onCommitted: (c) => cfg_searchFontColor = c
        }
        ColorPicker {
            Kirigami.FormData.label: "Background:"
            colorValue: cfg_searchBackgroundColor
            onCommitted: (c) => cfg_searchBackgroundColor = c
        }
    }
}
