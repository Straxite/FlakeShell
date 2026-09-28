pragma Singleton
import QtQuick

// Overwritten by matugen on every wallpaper change (see Colors.qml.template).
// These are just fallback values so the shell still looks right before
// matugen has run for the first time.
QtObject {
    readonly property color accent: "#7ecfff"
    readonly property color bg: "#141414"
    readonly property color track: "#2a2a2a"
}
