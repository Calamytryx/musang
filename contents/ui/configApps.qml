import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_appGroupsJson: hiddenTextHolder.text

    // KConfigXT needs a real property to bind to; we mirror it into the TextArea manually
    // so we can validate JSON before committing.
    QtObject {
        id: hiddenTextHolder
        property string text: "[]"
    }

    Component.onCompleted: {
        editor.text = formatJson(hiddenTextHolder.text)
    }

    function formatJson(raw) {
        try {
            return JSON.stringify(JSON.parse(raw), null, 2)
        } catch (e) {
            return raw
        }
    }

    function validate() {
        try {
            let parsed = JSON.parse(editor.text)
            if (!Array.isArray(parsed)) {
                statusLabel.text = "Root element must be an array of groups."
                statusLabel.color = "#e06c75"
                return false
            }
            statusLabel.text = "Valid JSON — " + parsed.length + " top-level group(s)."
            statusLabel.color = "#98c379"
            hiddenTextHolder.text = JSON.stringify(parsed)
            return true
        } catch (e) {
            statusLabel.text = "Invalid JSON: " + e.message
            statusLabel.color = "#e06c75"
            return false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Edit your app groups and subgroups as JSON below. Each group can have its own 'apps' list and/or nested 'subgroups'. Click 'Validate & Apply' before leaving this tab, then press Apply/OK on the settings window."
            opacity: 0.8
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            QQC2.TextArea {
                id: editor
                wrapMode: TextEdit.NoWrap
                font.family: "monospace"
                font.pixelSize: 13
                selectByMouse: true
                onTextChanged: validateTimer.restart()
            }
        }

        Timer {
            id: validateTimer
            interval: 600
            onTriggered: page.validate()
        }

        RowLayout {
            Layout.fillWidth: true

            QQC2.Label {
                id: statusLabel
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Edit JSON above, then click Validate & Apply."
            }

            QQC2.Button {
                text: "Validate && Apply"
                onClicked: page.validate()
            }

            QQC2.Button {
                text: "Format"
                onClicked: {
                    if (page.validate()) {
                        editor.text = page.formatJson(hiddenTextHolder.text)
                    }
                }
            }

            QQC2.Button {
                text: "Load example (12 groups)"
                onClicked: {
                    editor.text = page.formatJson(JSON.stringify(exampleData))
                }
            }
        }
    }

    property var exampleData: [
        {
            name: "System",
            expanded: true,
            apps: [
                { name: "Settings" },
                { name: "Terminal" },
                { name: "File Manager" }
            ],
            subgroups: []
        },
        {
            name: "Media",
            expanded: false,
            apps: [
                { name: "VLC" },
                { name: "Audacity" }
            ],
            subgroups: [
                {
                    name: "Editing",
                    expanded: false,
                    apps: [
                        { name: "Kdenlive" },
                        { name: "Shotcut" }
                    ]
                }
            ]
        },
        {
            name: "Development",
            expanded: false,
            apps: [
                { name: "VS Code" },
                { name: "Git" }
            ],
            subgroups: [
                {
                    name: "Build Tools",
                    expanded: false,
                    apps: [
                        { name: "CMake" },
                        { name: "Make" }
                    ]
                },
                {
                    name: "Debugging",
                    expanded: false,
                    apps: [
                        { name: "GDB" }
                    ]
                }
            ]
        },
        { name: "Internet", expanded: false, apps: [{ name: "Firefox" }], subgroups: [] },
        { name: "Office", expanded: false, apps: [{ name: "LibreOffice" }], subgroups: [] },
        { name: "Graphics", expanded: false, apps: [{ name: "GIMP" }, { name: "Krita" }], subgroups: [] },
        { name: "Gaming", expanded: false, apps: [{ name: "Steam" }], subgroups: [] },
        { name: "Streaming", expanded: false, apps: [{ name: "OBS Studio" }], subgroups: [] },
        { name: "Utilities", expanded: false, apps: [{ name: "Archive Manager" }], subgroups: [] },
        { name: "Customization", expanded: false, apps: [{ name: "System Settings" }], subgroups: [] },
        { name: "Communication", expanded: false, apps: [{ name: "Discord" }], subgroups: [] },
        { name: "Misc", expanded: false, apps: [{ name: "Calculator" }], subgroups: [] }
    ]
}
