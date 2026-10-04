pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ─────────────────────────────
    // Primary
    // ─────────────────────────────

    readonly property color primary: "#e8c26c"
    readonly property color m3onPrimary: "#3f2e00"
    readonly property color primaryContainer: "#5b4300"
    readonly property color m3onPrimaryContainer: "#ffdf9b"

    // ─────────────────────────────
    // Secondary
    // ─────────────────────────────

    readonly property color secondary: "#d7c4a0"
    readonly property color m3onSecondary: "#3a2f15"
    readonly property color secondaryContainer: "#52452a"
    readonly property color m3onSecondaryContainer: "#f4e0bb"

    // ─────────────────────────────
    // Tertiary
    // ─────────────────────────────

    readonly property color tertiary: "#b0cfaa"
    readonly property color m3onTertiary: "#1c361c"
    readonly property color tertiaryContainer: "#324d31"
    readonly property color m3onTertiaryContainer: "#cbebc5"

    // ─────────────────────────────
    // Background / Surface
    // ─────────────────────────────

    readonly property color background: "#17130b"
    readonly property color m3onBackground: "#ebe1d4"

    readonly property color surface: "#17130b"
    readonly property color m3onSurface: "#ebe1d4"
    readonly property color surfaceVariant: "#4d4639"
    readonly property color m3onSurfaceVariant: "#d0c5b4"

    // ─────────────────────────────
    // Surface Containers
    // ─────────────────────────────

    readonly property color surfaceDim: "#17130b"
    readonly property color surfaceBright: "#3e392f"

    readonly property color surfaceContainerLowest: "#110e07"
    readonly property color surfaceContainerLow: "#1f1b13"
    readonly property color surfaceContainer: "#231f17"
    readonly property color surfaceContainerHigh: "#2e2921"
    readonly property color surfaceContainerHighest: "#39342b"

    // ─────────────────────────────
    // Utility
    // ─────────────────────────────

    readonly property color outline: "#999080"
    readonly property color outlineVariant: "#4d4639"

    readonly property color error: "#ffb4ab"
    readonly property color m3onError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color m3onErrorContainer: "#ffdad6"

    readonly property color inverseSurface: "#ebe1d4"
    readonly property color inverseOnSurface: "#353027"
    readonly property color inversePrimary: "#775a0b"

    readonly property color scrim: "#000000"
    readonly property color shadow: "#000000"

    // Original wallpaper-derived color
    readonly property color sourceColor: "#92856c"
}
