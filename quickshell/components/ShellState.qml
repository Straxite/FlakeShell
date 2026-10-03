pragma Singleton
import QtQuick
import Quickshell

// Which panel is open in the pill: "" (none), "control", "capture", "clipboard" or "power".
// Pill.qml reads this to size/show the pill; the panels call close() when they are done.
Singleton {
  property string panel: ""
  property int nightLightTemperature: 4500   // Kelvin, 2500..6000

  function open(name) { panel = name }
  function toggle(name) { panel = (panel === name) ? "" : name }
  function close() { panel = "" }
}
