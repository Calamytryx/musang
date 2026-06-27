import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Appearance"
        icon: "preferences-desktop-font"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: "Apps"
        icon: "preferences-system-applications"
        source: "configApps.qml"
    }
}
