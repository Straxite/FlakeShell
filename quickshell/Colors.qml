pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ─────────────────────────────
    // Primary
    // ─────────────────────────────

    readonly property color primary: "#adc6ff"
    readonly property color m3onPrimary: "#112f60"
    readonly property color primaryContainer: "#2b4678"
    readonly property color m3onPrimaryContainer: "#d8e2ff"

    // ─────────────────────────────
    // Secondary
    // ─────────────────────────────

    readonly property color secondary: "#bfc6dc"
    readonly property color m3onSecondary: "#293041"
    readonly property color secondaryContainer: "#3f4759"
    readonly property color m3onSecondaryContainer: "#dbe2f9"

    // ─────────────────────────────
    // Tertiary
    // ─────────────────────────────

    readonly property color tertiary: "#debcdf"
    readonly property color m3onTertiary: "#402843"
    readonly property color tertiaryContainer: "#583e5b"
    readonly property color m3onTertiaryContainer: "#fbd7fc"

    // ─────────────────────────────
    // Background / Surface
    // ─────────────────────────────

    readonly property color background: "#111318"
    readonly property color m3onBackground: "#e2e2e9"

    readonly property color surface: "#111318"
    readonly property color m3onSurface: "#e2e2e9"
    readonly property color surfaceVariant: "#44474f"
    readonly property color m3onSurfaceVariant: "#c4c6d0"

    // ─────────────────────────────
    // Surface Containers
    // ─────────────────────────────

    readonly property color surfaceDim: "#111318"
    readonly property color surfaceBright: "#37393e"

    readonly property color surfaceContainerLowest: "#0c0e13"
    readonly property color surfaceContainerLow: "#1a1b20"
    readonly property color surfaceContainer: "#1e1f25"
    readonly property color surfaceContainerHigh: "#282a2f"
    readonly property color surfaceContainerHighest: "#33353a"

    // ─────────────────────────────
    // Utility
    // ─────────────────────────────

    readonly property color outline: "#8e9099"
    readonly property color outlineVariant: "#44474f"

    readonly property color error: "#ffb4ab"
    readonly property color m3onError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color m3onErrorContainer: "#ffdad6"

    readonly property color inverseSurface: "#e2e2e9"
    readonly property color inverseOnSurface: "#2f3036"
    readonly property color inversePrimary: "#445e91"

    readonly property color scrim: "#000000"
    readonly property color shadow: "#000000"

    // Original wallpaper-derived color
    readonly property color sourceColor: "#313b51"
}
