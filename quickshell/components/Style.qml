pragma Singleton
import QtQuick
import Quickshell

// Colors / sizes for the four panels. (Named Style, not Theme, because your
// components/Theme.qml is the theme *menu*.) Change the look here, once.
Singleton {
  // font: needs a Nerd Font so the icon glyphs show up. Change to the one you use.
  readonly property string fontFamily: "JetBrainsMono Nerd Font"

  // shapes + speeds
  readonly property int radius: 12
  readonly property int radiusSmall: 8
  readonly property int animationFast: 150
  readonly property int animationNormal: 300   // same as the pill's own expand animation

  // greys, darkest -> lightest (the pill itself is pure black)
  readonly property color bgDim: "#050506"     // text drawn on top of the accent color
  readonly property color bg0: "#0d0d0f"
  readonly property color bg1: "#17171a"
  readonly property color bg2: "#222226"
  readonly property color bg3: "#33333a"

  // text
  readonly property color foreground: "#e6e6ea"
  readonly property color muted: "#9a9aa3"
  readonly property color mutedDark: "#62626b"

  // accents (your #7ecfff blue + #e05c5c red)
  readonly property color primary: "#7ecfff"
  readonly property color primaryContainer: "#16384d"
  readonly property color red: "#e05c5c"
  readonly property color yellow: "#e5c07b"
  readonly property color bgYellow: "#2b2616"
}
