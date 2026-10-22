pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ─────────────────────────────
    // Primary
    // ─────────────────────────────

    readonly property color primary: "#a8c8ff"
    readonly property color m3onPrimary: "#06305f"
    readonly property color primaryContainer: "#254777"
    readonly property color m3onPrimaryContainer: "#d5e3ff"

    // ─────────────────────────────
    // Secondary
    // ─────────────────────────────

    readonly property color secondary: "#bdc7dc"
    readonly property color m3onSecondary: "#273141"
    readonly property color secondaryContainer: "#3e4758"
    readonly property color m3onSecondaryContainer: "#d9e3f8"

    // ─────────────────────────────
    // Tertiary
    // ─────────────────────────────

    readonly property color tertiary: "#dbbce1"
    readonly property color m3onTertiary: "#3e2845"
    readonly property color tertiaryContainer: "#563e5d"
    readonly property color m3onTertiaryContainer: "#f8d8fe"

    // ─────────────────────────────
    // Background / Surface
    // ─────────────────────────────

    readonly property color background: "#111318"
    readonly property color m3onBackground: "#e1e2e9"

    readonly property color surface: "#111318"
    readonly property color m3onSurface: "#e1e2e9"
    readonly property color surfaceVariant: "#43474e"
    readonly property color m3onSurfaceVariant: "#c4c6cf"

    // ─────────────────────────────
    // Surface Containers
    // ─────────────────────────────

    readonly property color surfaceDim: "#111318"
    readonly property color surfaceBright: "#37393e"

    readonly property color surfaceContainerLowest: "#0c0e13"
    readonly property color surfaceContainerLow: "#191c20"
    readonly property color surfaceContainer: "#1d2024"
    readonly property color surfaceContainerHigh: "#282a2f"
    readonly property color surfaceContainerHighest: "#33353a"

    // ─────────────────────────────
    // Utility
    // ─────────────────────────────

    readonly property color outline: "#8e9099"
    readonly property color outlineVariant: "#43474e"

    readonly property color error: "#ffb4ab"
    readonly property color m3onError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color m3onErrorContainer: "#ffdad6"

    readonly property color inverseSurface: "#e1e2e9"
    readonly property color inverseOnSurface: "#2e3035"
    readonly property color inversePrimary: "#3f5f90"

    readonly property color scrim: "#000000"
    readonly property color shadow: "#000000"

    // Original wallpaper-derived color
    readonly property color sourceColor: "#465165"
}
