import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    focus: true

    property var searchInputRef: null

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                root.focus = true
                Qt.callLater(() => {
                    if (root.searchInputRef) {
                        root.searchInputRef.forceActiveFocus()
                        root.searchInputRef.selectAll()
                    }
                })
            }
        }
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: plasmoid.configuration.plasmoidIcon.length > 0
    ? plasmoid.configuration.plasmoidIcon
    : Qt.resolvedUrl("../../musang.png").toString().replace("file://", "")

    Layout.minimumWidth:    Kirigami.Units.gridUnit * 20
    Layout.minimumHeight:   Kirigami.Units.gridUnit * 25
    Layout.preferredWidth:  Kirigami.Units.gridUnit * 25
    Layout.preferredHeight: Kirigami.Units.gridUnit * 30

    // ---- Clock / date ----
    property int    hours:      0
    property int    minutes:    0
    property string ampm:       "AM"
    property string dayName:    ""
    property int    dayOfMonth: 0
    property int    month:      0
    property int    year:       0
    property int    dayOfYear:  0
    property int    daysInYear: 365

    // ---- Battery & System Info ----
    property int    batteryPercent: 0
    property string batteryStatus:  "Unknown"
    property bool   isCharging:     false
    property string chargeMode: "Unknown"
    property real chargeRate: 0.0
    property real dischargeRate: 0.0

    Plasma5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        onSourceAdded: function(source) {
            connectSource(source)
        }
        onDataChanged: {
            let bat = pmSource.data["Battery"]
            if (!bat) return
                batteryPercent = bat["Percent"] !== undefined ? bat["Percent"] : 0
                let state = bat["State"] || ""
                let fullyCharged = (batteryPercent === 100)
                isCharging = (state === "Charging" || fullyCharged)
                chargeMode = fullyCharged ? "FullyCharged"
                : state === "NoCharge" ? "Capped"
                : state ? state
                : "Unknown"
                batteryStatus = chargeMode
                let power = bat["EnergyRate"]
                if (power !== undefined && power !== null) {
                    power = Math.round(power * 10) / 10
                    if (state === "Charging") {
                        chargeRate = power
                        dischargeRate = 0.0
                    }
                    else if (state === "Discharging" || state === "NoCharge") {
                        dischargeRate = Math.abs(power)
                        chargeRate = 0.0
                    }
                    else {
                        chargeRate = 0.0
                        dischargeRate = 0.0
                    }
                } else {
                    chargeRate = 0.0
                    dischargeRate = 0.0
                }
        }
    }

    property string searchText: ""
    property bool   scanning:   false

    // ---- Spinner state ----
    // Frames cycle /  -  \  |  then repeat.
    // When scan finishes we let the current cycle complete before stopping.
    readonly property var spinFrames: ["/", "-", "\\", "|"]
    property int  spinIndex:      0   // which frame we're on
    property int  spinCyclePos:   0   // how far into the current cycle (0-3)
    property bool spinDraining:   false  // true = scan done, finish this cycle then stop

    Timer {
        id: spinTimer
        interval: 120
        running:  false
        repeat:   true
        onTriggered: {
            root.spinIndex    = (root.spinIndex + 1) % 4
            root.spinCyclePos = (root.spinCyclePos + 1) % 4

            // If scan already finished and we just completed a full cycle, stop
            if (root.spinDraining && root.spinCyclePos === 0) {
                spinTimer.stop()
                root.spinDraining = false
            }
        }
    }

    // Call this to start spinning
    function startSpinner() {
        spinIndex    = 0
        spinCyclePos = 0
        spinDraining = false
        spinTimer.start()
    }

    // Call this when scan finishes — lets the current cycle complete
    function stopSpinner() {
        if (spinCyclePos === 0) {
            // Already at cycle boundary, stop immediately
            spinTimer.stop()
        } else {
            // Let it drain to the end of this cycle
            spinDraining = true
        }
    }

    property var appGroups: []
    property var flatRows:  []

    readonly property string scanScript:
    Qt.resolvedUrl("../../scan-apps.py").toString().replace(/^file:\/\//, "")

    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            let out = (data["stdout"] || "").trim()
            if (out.length > 0) {
                try {
                    let parsed = JSON.parse(out)
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        plasmoid.configuration.appGroupsJson = JSON.stringify(parsed)
                        appGroups = parsed
                        rebuildFlatRows()
                    }
                } catch(e) {
                    console.log("TextLauncher scan-apps parse error:", e.message)
                }
            }
            disconnectSource(source)
            root.scanning = false
            root.stopSpinner()
        }
    }

    function scanApps() {
        root.scanning = true
        root.startSpinner()
        execSource.connectSource("python3 " + scanScript)
    }

    function reloadAppGroups() {
        try {
            let raw    = plasmoid.configuration.appGroupsJson
            let parsed = JSON.parse(raw && raw.length ? raw : "[]")
            if (!Array.isArray(parsed)) parsed = []
                appGroups = parsed
        } catch (e) {
            appGroups = []
        }
        rebuildFlatRows()
    }

    function colorOr(cfgValue, fallback) {
        return (cfgValue && cfgValue.length > 0) ? cfgValue : fallback
    }

    Component.onCompleted: {
        updateTime()
        let raw = plasmoid.configuration.appGroupsJson
        if (!raw || raw === "[]" || raw.trim() === "") {
            scanApps()
        } else {
            reloadAppGroups()
        }
    }

    Connections {
        target: plasmoid.configuration
        function onAppGroupsJsonChanged() { reloadAppGroups() }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: updateTime()
    }

    function updateTime() {
        let now = new Date()
        let h   = now.getHours()
        ampm    = h >= 12 ? "PM" : "AM"
        let h12 = h % 12; if (h12 === 0) h12 = 12
        hours      = h12
        minutes    = now.getMinutes()
        let days   = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        dayName    = days[now.getDay()]
        dayOfMonth = now.getDate()
        month      = now.getMonth() + 1
        year       = now.getFullYear()
        let isLeap = (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0)
        daysInYear = isLeap ? 366 : 365
        dayOfYear  = Math.floor((now - new Date(year, 0, 0)) / 86400000)
    }

    function rebuildFlatRows() {
        let rows  = []
        let stack = []
        for (let i = appGroups.length - 1; i >= 0; i--)
            stack.push({ node: appGroups[i], depth: 0, key: String(i) })
            while (stack.length > 0) {
                let { node, depth, key } = stack.pop()
                rows.push({ kind: "group", depth: depth, name: node.name,
                    expanded: !!node.expanded, keyPath: key })
                if (node.expanded) {
                    let apps = node.apps || []
                    for (let a = 0; a < apps.length; a++)
                        rows.push({ kind: "app", depth: depth + 1,
                            name: apps[a].name, exec: apps[a].exec || "",
                            keyPath: key + ".a" + a })
                        let subs = node.subgroups || []
                        for (let s = subs.length - 1; s >= 0; s--)
                            stack.push({ node: subs[s], depth: depth + 1, key: key + "." + s })
                }
            }
            flatRows = rows
    }

    function toggleByKey(keyPath) {
        let copy    = JSON.parse(JSON.stringify(appGroups))
        let indices = keyPath.split(".").filter(p => !/^a/.test(p)).map(Number)
        let node    = { subgroups: copy }
        for (let i = 0; i < indices.length; i++) node = node.subgroups[indices[i]]
            node.expanded = !node.expanded
            appGroups = copy
            rebuildFlatRows()
    }

    Plasma5Support.DataSource {
        id: launchSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }
    }

    Plasma5Support.DataSource {
        id: kmenueditSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }
    }

    function launchApp(execLine) {
        let cmd = execLine.replace(/%[uUfFdDnNickvm]/g, "").trim()
        launchSource.connectSource(cmd)
    }

    function powerAction(action) {
        let cmd = ""
        switch(action) {
            case "sleep":     cmd = "qdbus org.kde.ksmserver /KSMServer suspend"; break
            case "hibernate": cmd = "qdbus org.kde.ksmserver /KSMServer hibernate"; break
            case "shutdown":  cmd = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown"; break
            case "restart":   cmd = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot"; break
            case "logout":    cmd = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptLogout"; break
        }
        if (cmd) launchSource.connectSource(cmd)
    }

    readonly property var displayRows: (function() {
        let q = searchText.trim().toLowerCase()
        if (q === "") return flatRows
            let results = []
            function processNode(node, depth, keyPath) {
                let hasMatch = false
                let children = []
                let apps = node.apps || []
                for (let i = 0; i < apps.length; i++) {
                    let app = apps[i]
                    let name = (app.name || "").toLowerCase()
                    if (name.indexOf(q) !== -1) {
                        hasMatch = true
                        children.push({
                            kind: "app",
                            depth: depth + 1,
                            name: app.name,
                            exec: app.exec || "",
                            keyPath: keyPath + ".a" + i
                        })
                    }
                }
                let subs = node.subgroups || []
                for (let s = 0; s < subs.length; s++) {
                    let subKey = keyPath + "." + s
                    let sub = processNode(subs[s], depth + 1, subKey)
                    if (sub.hasMatch) {
                        hasMatch = true
                        children.push({
                            kind: "group",
                            depth: depth + 1,
                            name: subs[s].name,
                            expanded: true,
                            keyPath: subKey
                        })
                        children = children.concat(sub.rows)
                    }
                }
                let rows = []
                if (hasMatch) {
                    rows.push({
                        kind: "group",
                        depth: depth,
                        name: node.name,
                        expanded: true,
                        keyPath: keyPath
                    })
                    rows = rows.concat(children)
                }
                return { hasMatch: hasMatch, rows: rows }
            }
            for (let i = 0; i < appGroups.length; i++) {
                let res = processNode(appGroups[i], 0, String(i))
                results = results.concat(res.rows)
            }
            return results
    })()

    fullRepresentation: Rectangle {
        id: bg
        color: root.colorOr(plasmoid.configuration.widgetBackgroundColor, Kirigami.Theme.backgroundColor)
        readonly property string gFont: plasmoid.configuration.globalFontFamily || ""

        ColumnLayout {
            anchors { fill: parent; margins: Kirigami.Units.smallSpacing }
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Text {
                    text: String(root.hours).padStart(2,'0') + ":" + String(root.minutes).padStart(2,'0') + " " + root.ampm
                    font.family: bg.gFont
                    font.pixelSize: Kirigami.Units.gridUnit * (plasmoid.configuration.clockFontSize || 1.5)
                    font.bold: true
                    color: root.colorOr(plasmoid.configuration.clockFontColor, Kirigami.Theme.textColor)
                    Layout.fillWidth: true
                }
                Text {
                    // Show spinner frame when scanning/draining, otherwise [+]
                    text: (root.scanning || root.spinDraining)
                    ? "[" + root.spinFrames[root.spinIndex] + "]"
                    : "[*]"
                    font.family: bg.gFont
                    font.pixelSize: Kirigami.Units.gridUnit * 0.85
                    color: root.colorOr(plasmoid.configuration.clockFontColor, Kirigami.Theme.textColor)
                    opacity: (root.scanning || root.spinDraining) ? 1.0 : 0.5
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.scanning && !root.spinDraining
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scanApps()
                    }
                }
                Text {
                    text: "[+]"
                    font.family: bg.gFont
                    font.pixelSize: Kirigami.Units.gridUnit * 0.85
                    color: root.colorOr(plasmoid.configuration.clockFontColor, Kirigami.Theme.textColor)
                    opacity: 0.5
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: kmenueditSource.connectSource("kmenuedit")
                    }
                }
            }

            Text {
                text: " " + root.dayName + " :: " + String(root.dayOfMonth).padStart(2,'0') + "/" + String(root.month).padStart(2,'0') + "/" + root.year + " :: " + root.dayOfYear + "/" + root.daysInYear
                font.family: bg.gFont
                font.pixelSize: Kirigami.Units.gridUnit * (plasmoid.configuration.dateFontSize || 1.0)
                color: root.colorOr(plasmoid.configuration.dateFontColor, Kirigami.Theme.textColor)
                Layout.alignment: Qt.AlignLeft
            }

            Text {
                text: {
                    let icon = root.isCharging ? "" :
                    root.batteryPercent <= 5  ? "" :
                    root.batteryPercent <= 10 ? "" :
                    root.batteryPercent <= 20 ? "" :
                    root.batteryPercent <= 30 ? "" :
                    root.batteryPercent <= 40 ? "" :
                    root.batteryPercent <= 50 ? "" :
                    root.batteryPercent <= 60 ? "" :
                    root.batteryPercent <= 70 ? "" :
                    root.batteryPercent <= 80 ? "" :
                    root.batteryPercent <= 90 ? "" :
                    ""

                    let rateMultiplier = root.dischargeRate > 0
                    ? (root.dischargeRate.toFixed(1) + "x")
                    : (root.chargeRate > 0
                    ? (root.chargeRate.toFixed(1) + "x")
                    : "0.0x")

                    return icon + " " + root.batteryPercent + "% :: "
                    + root.batteryStatus + " "
                    + rateMultiplier
                }
                font.family: bg.gFont
                font.pixelSize: Kirigami.Units.gridUnit * (plasmoid.configuration.batteryFontSize || 1.0)
                color: root.colorOr(plasmoid.configuration.batteryFontColor, Kirigami.Theme.textColor)
                Layout.alignment: Qt.AlignLeft
            }

            // Power controls (collapsible)
            Column {
                Layout.fillWidth: true
                spacing: 0

                property bool expanded: false

                MouseArea {
                    width: parent.width
                    height: Kirigami.Units.gridUnit * 1.5
                    hoverEnabled: true

                    onClicked: parent.expanded = !parent.expanded

                    Rectangle {
                        anchors.fill: parent
                        color: root.colorOr(
                            plasmoid.configuration.groupHeaderBackgroundColor,
                            parent.containsMouse
                            ? Kirigami.Theme.highlightColor
                            : "transparent"
                        )
                        opacity: 0.2
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: Kirigami.Units.smallSpacing
                            verticalCenter: parent.verticalCenter
                        }
                        text: (parent.parent.expanded ? "[-] " : "[+] ") +
                        (plasmoid.configuration.powerGroupName || "Power")
                        font.family: bg.gFont
                        font.pixelSize: Kirigami.Units.gridUnit *
                        (plasmoid.configuration.groupHeaderFontSize || 1.1)
                        font.bold: true
                        color: root.colorOr(
                            plasmoid.configuration.groupHeaderFontColor,
                            Kirigami.Theme.textColor
                        )
                    }
                }

                Column {
                    visible: parent.expanded
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: [
                            { name: "⏾ Sleep",      action: "sleep" },
                            { name: "❄ Hibernate",  action: "hibernate" },
                            { name: "⏻ Shutdown",   action: "shutdown" },
                            { name: "↻ Restart",    action: "restart" },
                            { name: "↩ Logout",     action: "logout" }
                        ]

                        delegate: MouseArea {
                            width: parent.width
                            height: Kirigami.Units.gridUnit * 1.2
                            hoverEnabled: true

                            onClicked: root.powerAction(modelData.action)

                            Rectangle {
                                anchors.fill: parent
                                color: root.colorOr(
                                    plasmoid.configuration.groupItemBackgroundColor,
                                    parent.containsMouse
                                    ? Kirigami.Theme.highlightColor
                                    : "transparent"
                                )
                                opacity: 0.2
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: Kirigami.Units.smallSpacing +
                                    Kirigami.Units.largeSpacing
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.name
                                font.family: bg.gFont
                                font.pixelSize: Kirigami.Units.gridUnit *
                                (plasmoid.configuration.groupItemFontSize || 1.0)
                                color: root.colorOr(
                                    plasmoid.configuration.groupItemFontColor,
                                    Kirigami.Theme.textColor
                                )
                            }
                        }
                    }
                }
            }

            RowLayout {
                visible: root.flatRows.length === 0
                Layout.fillWidth: true
                Text {
                    text: "No apps — "
                    font.pixelSize: Kirigami.Units.gridUnit * 0.9
                    color: Kirigami.Theme.textColor; opacity: 0.6
                }
                Text {
                    text: "[scan]"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.9
                    color: Kirigami.Theme.highlightColor
                    MouseArea { anchors.fill: parent; onClicked: root.scanApps() }
                }
            }

            ScrollView {
                id: appScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Column {
                    width: appScroll.availableWidth
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.displayRows

                        delegate: MouseArea {
                            width: parent.width
                            height: modelData.kind === "group"
                            ? Kirigami.Units.gridUnit * 1.5
                            : Kirigami.Units.gridUnit * 1.2
                            hoverEnabled: true

                            onClicked: {
                                if (modelData.kind === "group")
                                    root.toggleByKey(modelData.keyPath)
                                    else
                                        root.launchApp(modelData.exec)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: {
                                    let c = modelData.kind === "group"
                                    ? plasmoid.configuration.groupHeaderBackgroundColor
                                    : plasmoid.configuration.groupItemBackgroundColor
                                    return (c && c.length > 0)
                                    ? c
                                    : (parent.containsMouse ? Kirigami.Theme.highlightColor : "transparent")
                                }
                                opacity: {
                                    let c = modelData.kind === "group"
                                    ? plasmoid.configuration.groupHeaderBackgroundColor
                                    : plasmoid.configuration.groupItemBackgroundColor
                                    return (c && c.length > 0) ? 1.0 : 0.2
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: Kirigami.Units.smallSpacing +
                                    modelData.depth * Kirigami.Units.largeSpacing
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.kind === "group"
                                ? ((modelData.expanded ? "[-] " : "[+] ") + modelData.name)
                                : modelData.name
                                font.family: bg.gFont
                                font.pixelSize: Kirigami.Units.gridUnit *
                                (modelData.kind === "group"
                                ? (plasmoid.configuration.groupHeaderFontSize || 1.1)
                                : (plasmoid.configuration.groupItemFontSize  || 1.0))
                                font.bold: modelData.kind === "group"
                                color: modelData.kind === "group"
                                ? root.colorOr(plasmoid.configuration.groupHeaderFontColor, Kirigami.Theme.textColor)
                                : root.colorOr(plasmoid.configuration.groupItemFontColor,   Kirigami.Theme.textColor)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 2
                color: root.colorOr(plasmoid.configuration.searchBackgroundColor, Kirigami.Theme.backgroundColor)
                border.color: Kirigami.Theme.textColor; border.width: 1

                TextInput {
                    id: searchInput
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing }
                    font.family: bg.gFont
                    font.pixelSize: Kirigami.Units.gridUnit * (plasmoid.configuration.searchFontSize || 1.0)
                    color: root.colorOr(plasmoid.configuration.searchFontColor, Kirigami.Theme.textColor)
                    onTextChanged: root.searchText = text
                    Component.onCompleted: {
                        root.searchInputRef = searchInput
                        forceActiveFocus()
                    }
                }
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: searchInput.text === "" ? " Search..." : ""
                    font.family: bg.gFont
                    font.pixelSize: Kirigami.Units.gridUnit * (plasmoid.configuration.searchFontSize || 1.0)
                    color: root.colorOr(plasmoid.configuration.searchFontColor, Kirigami.Theme.textColor)
                    opacity: 0.5
                }
            }
        }
    }
}
