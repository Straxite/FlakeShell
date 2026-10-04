pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ─────────────────────────────
    // Primary
    // ─────────────────────────────

    readonly property color primary: "{{ colors.primary.default.hex }}"
    readonly property color m3onPrimary: "{{ colors.on_primary.default.hex }}"
    readonly property color primaryContainer: "{{ colors.primary_container.default.hex }}"
    readonly property color m3onPrimaryContainer: "{{ colors.on_primary_container.default.hex }}"

    // ─────────────────────────────
    // Secondary
    // ─────────────────────────────

    readonly property color secondary: "{{ colors.secondary.default.hex }}"
    readonly property color m3onSecondary: "{{ colors.on_secondary.default.hex }}"
    readonly property color secondaryContainer: "{{ colors.secondary_container.default.hex }}"
    readonly property color m3onSecondaryContainer: "{{ colors.on_secondary_container.default.hex }}"

    // ─────────────────────────────
    // Tertiary
    // ─────────────────────────────

    readonly property color tertiary: "{{ colors.tertiary.default.hex }}"
    readonly property color m3onTertiary: "{{ colors.on_tertiary.default.hex }}"
    readonly property color tertiaryContainer: "{{ colors.tertiary_container.default.hex }}"
    readonly property color m3onTertiaryContainer: "{{ colors.on_tertiary_container.default.hex }}"

    // ─────────────────────────────
    // Background / Surface
    // ─────────────────────────────

    readonly property color background: "{{ colors.background.default.hex }}"
    readonly property color m3onBackground: "{{ colors.on_background.default.hex }}"

    readonly property color surface: "{{ colors.surface.default.hex }}"
    readonly property color m3onSurface: "{{ colors.on_surface.default.hex }}"
    readonly property color surfaceVariant: "{{ colors.surface_variant.default.hex }}"
    readonly property color m3onSurfaceVariant: "{{ colors.on_surface_variant.default.hex }}"

    // ─────────────────────────────
    // Surface Containers
    // ─────────────────────────────

    readonly property color surfaceDim: "{{ colors.surface_dim.default.hex }}"
    readonly property color surfaceBright: "{{ colors.surface_bright.default.hex }}"

    readonly property color surfaceContainerLowest: "{{ colors.surface_container_lowest.default.hex }}"
    readonly property color surfaceContainerLow: "{{ colors.surface_container_low.default.hex }}"
    readonly property color surfaceContainer: "{{ colors.surface_container.default.hex }}"
    readonly property color surfaceContainerHigh: "{{ colors.surface_container_high.default.hex }}"
    readonly property color surfaceContainerHighest: "{{ colors.surface_container_highest.default.hex }}"

    // ─────────────────────────────
    // Utility
    // ─────────────────────────────

    readonly property color outline: "{{ colors.outline.default.hex }}"
    readonly property color outlineVariant: "{{ colors.outline_variant.default.hex }}"

    readonly property color error: "{{ colors.error.default.hex }}"
    readonly property color m3onError: "{{ colors.on_error.default.hex }}"
    readonly property color errorContainer: "{{ colors.error_container.default.hex }}"
    readonly property color m3onErrorContainer: "{{ colors.on_error_container.default.hex }}"

    readonly property color inverseSurface: "{{ colors.inverse_surface.default.hex }}"
    readonly property color inverseOnSurface: "{{ colors.inverse_on_surface.default.hex }}"
    readonly property color inversePrimary: "{{ colors.inverse_primary.default.hex }}"

    readonly property color scrim: "{{ colors.scrim.default.hex }}"
    readonly property color shadow: "{{ colors.shadow.default.hex }}"

    // Original wallpaper-derived color
    readonly property color sourceColor: "{{ colors.source_color.default.hex }}"
}
