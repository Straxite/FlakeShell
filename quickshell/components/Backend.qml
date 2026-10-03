pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Everything the panels need to actually *do* things (run commands, read state).
// Tools used: cliphist + wl-clipboard, grim + slurp (+ jq), wf-recorder, brightnessctl,
// powerprofilesctl, hyprsunset, hyprlock, systemctl, hyprctl. Missing tool = that one feature does nothing.
Singleton {
  id: backend

  // ───────────── POWER ─────────────
  function power(action) {
    const commands = {
      "lock": ["hyprlock"],
      "suspend": ["systemctl", "suspend"],
      "logout": ["hyprctl", "dispatch", "exit"],
      "reboot": ["systemctl", "reboot"],
      "shutdown": ["systemctl", "poweroff"]
    };
    if (commands[action])
      Quickshell.execDetached(commands[action]);
  }

  // ───────────── CLIPBOARD (cliphist) ─────────────
  property var clipboardItems: []            // [{ id, preview, imageSource }], newest first
  property string clipboardContents: ""      // full text of the previewed entry
  property bool clipboardContentsLoading: false
  property string clipboardImageSource: ""   // set instead of clipboardContents when the entry is an image

  function refreshClipboard() {
    if (!clipList.running)
      clipList.running = true;
  }

  // Lists the last 60 entries. Image entries are decoded once to a cache file so they can be thumbnails.
  // Output per line:  id <TAB> preview <TAB> imageFile-or-empty
  Process {
    id: clipList
    command: ["bash", "-c", [
      "d=\"${XDG_RUNTIME_DIR:-/tmp}/pill-clipboard\"",
      "mkdir -p \"$d\"",
      "cliphist list | head -n 60 | while IFS=$'\\t' read -r id rest; do",
      "  f=''",
      "  case \"$rest\" in",
      "    '[[ binary data'*)",
      "      f=\"$d/$id.img\"",
      "      [ -s \"$f\" ] || cliphist decode \"$id\" > \"$f\" 2>/dev/null",
      "      ;;",
      "  esac",
      "  printf '%s\\t%s\\t%s\\n' \"$id\" \"$rest\" \"$f\"",
      "done"
    ].join("\n")]
    stdout: StdioCollector {
      onStreamFinished: {
        const items = [];
        for (const line of text.split("\n")) {
          const parts = line.split("\t");
          if (parts.length < 3)
            continue;
          const file = parts[parts.length - 1];
          items.push({
            "id": parts[0],
            "preview": parts.slice(1, -1).join(" "),
            "imageSource": file ? "file://" + file : ""
          });
        }
        backend.clipboardItems = items;
      }
    }
  }

  // Full content of one entry (text). Only the newest request is shown if you move quickly.
  property string wantedClipId: ""

  function loadClipboardContents(id, preview, imageSource) {
    if (imageSource) {
      clipboardImageSource = imageSource;
      clipboardContents = "";
      clipboardContentsLoading = false;
      return;
    }
    clipboardImageSource = "";
    clipboardContentsLoading = true;
    wantedClipId = id;
    if (!clipDecode.running)
      startDecode();
  }

  function startDecode() {
    clipDecode.decodingId = wantedClipId;
    clipDecode.command = ["cliphist", "decode", wantedClipId];
    clipDecode.running = true;
  }

  Process {
    id: clipDecode
    property string decodingId: ""
    stdout: StdioCollector {
      onStreamFinished: {
        if (clipDecode.decodingId !== backend.wantedClipId)
          return;
        backend.clipboardContents = text.length > 20000 ? text.slice(0, 20000) + "…" : text;
        backend.clipboardContentsLoading = false;
      }
    }
    onExited: {
      if (decodingId !== backend.wantedClipId)
        backend.startDecode();
    }
  }

  // Puts the chosen entry back on the clipboard (then ctrl+v wherever you want it).
  function pasteClipboard(id) {
    Quickshell.execDetached(["bash", "-c", "cliphist decode \"$1\" | wl-copy", "_", String(id)]);
  }

  // ───────────── CAPTURE (screenshots + recording) ─────────────
  property string lastError: ""
  property string lastCapture: ""
  readonly property bool recording: recorder.running

  // mode: "full" | "window" | "region"
  function capture(mode) {
    if (shot.running)
      return;
    lastError = "";
    lastCapture = "";
    shot.command = ["bash", "-c", [
      "mode=\"$1\"",
      "dir=\"$HOME/Pictures\"; mkdir -p \"$dir\"",
      "f=\"$dir/screenshot_$(date +%Y%m%d_%H%M%S).png\"",
      "case \"$mode\" in",
      "  full) grim \"$f\" ;;",
      "  region)",
      "    geo=\"$(slurp 2>/dev/null)\" || exit 0",
      "    grim -g \"$geo\" \"$f\" ;;",
      "  window)",
      "    ws=\"$(hyprctl monitors -j | jq '[.[].activeWorkspace.id]')\"",
      "    geo=\"$(hyprctl clients -j | jq -r --argjson ws \"$ws\" '.[] | select(.workspace.id as $w | $ws | index($w)) | \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"' | slurp -r 2>/dev/null)\" || exit 0",
      "    grim -g \"$geo\" \"$f\" ;;",
      "esac",
      "[ -s \"$f\" ] || exit 0",
      "command -v notify-send >/dev/null && notify-send -i \"$f\" 'Screenshot saved' \"$f\"",
      "echo \"$f\""
    ].join("\n"), "_", mode];
    shot.running = true;
  }

  Process {
    id: shot
    stdout: StdioCollector {
      onStreamFinished: backend.lastCapture = text.trim()
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim().length > 0)
          backend.lastError = text.trim();
      }
    }
  }

  // Full-display WebM recording with wf-recorder; includes the mic if it's unmuted when you start.
  property bool stopRequested: false

  function toggleRecording() {
    if (recorder.running) {
      stopRequested = true;
      recorder.signal(2);   // SIGINT: wf-recorder finishes the file properly
      return;
    }
    const source = Pipewire.defaultAudioSource;
    const withAudio = source && source.audio && !source.audio.muted;
    lastError = "";
    lastCapture = "";
    stopRequested = false;
    recorder.command = ["bash", "-c", [
      "dir=\"$HOME/Videos\"; mkdir -p \"$dir\"",
      "f=\"$dir/recording_$(date +%Y%m%d_%H%M%S).webm\"",
      "args=(-c libvpx -p deadline=realtime -p cpu-used=8 -f \"$f\")",
      "[ \"$1\" = 1 ] && args+=(-a -C libopus)",
      "exec wf-recorder \"${args[@]}\""
    ].join("\n"), "_", withAudio ? "1" : "0"];
    recorder.running = true;
  }

  Process {
    id: recorder
    stderr: StdioCollector {
      onStreamFinished: {
        if (!backend.stopRequested && text.trim().length > 0)
          backend.lastError = text.trim();
      }
    }
    onExited: {
      if (backend.stopRequested)
        backend.lastCapture = "Recording saved to Videos";
    }
  }

  // ───────────── QUICK CONTROLS (brightness, power profile, night light) ─────────────
  function refreshQuickControls() {
    if (!profileGet.running)
      profileGet.running = true;
    if (!profileList.running)
      profileList.running = true;
  }

  // BRIGHTNESS: 0..100. Pill.qml's brightnessctl poll keeps this up to date; the slider calls setBrightness.
  property real brightness: 0
  property real pendingBrightness: 0

  function setBrightness(percent) {
    pendingBrightness = Math.max(1, Math.min(100, Math.round(percent)));
    brightness = pendingBrightness;
    brightnessThrottle.start();
  }

  Timer {
    id: brightnessThrottle
    interval: 50
    onTriggered: Quickshell.execDetached(["brightnessctl", "set", backend.pendingBrightness + "%"])
  }

  // POWER PROFILE: power-profiles-daemon via powerprofilesctl
  property string powerProfile: "balanced"
  property var profiles: ["power-saver", "balanced", "performance"]

  function cyclePowerProfile() {
    const next = profiles[(profiles.indexOf(powerProfile) + 1) % profiles.length];
    powerProfile = next;
    Quickshell.execDetached(["powerprofilesctl", "set", next]);
    profileRecheck.restart();
  }

  Timer {
    id: profileRecheck
    interval: 500
    onTriggered: if (!profileGet.running) profileGet.running = true
  }

  Process {
    id: profileGet
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        const name = text.trim();
        if (name)
          backend.powerProfile = name;
      }
    }
  }

  // Only cycle through the profiles this machine really has (many laptops have no "performance").
  Process {
    id: profileList
    command: ["powerprofilesctl", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const found = [];
        for (const line of text.split("\n")) {
          const match = line.match(/^[ *]*([a-z-]+):\s*$/);
          if (match)
            found.push(match[1]);
        }
        const order = ["power-saver", "balanced", "performance"].filter(name => found.indexOf(name) >= 0);
        if (order.length > 0)
          backend.profiles = order;
      }
    }
  }

  // NIGHT LIGHT: hyprsunset runs while it's "on"; temperature changes go through its IPC.
  property bool hasSunset: false
  readonly property string nightLightStatus: !hasSunset ? "unavailable" : (sunset.running ? "on" : "off")

  function toggleNightLight() {
    if (!hasSunset)
      return;
    if (sunset.running) {
      sunset.signal(15);   // SIGTERM: hyprsunset resets the screen colors on exit
      return;
    }
    sunset.command = ["hyprsunset", "-t", String(ShellState.nightLightTemperature)];
    sunset.running = true;
  }

  function setNightLightTemperature(kelvin) {
    ShellState.nightLightTemperature = Math.round(Math.max(2500, Math.min(6000, kelvin)) / 100) * 100;
    if (sunset.running)
      temperatureDebounce.restart();
  }

  Timer {
    id: temperatureDebounce
    interval: 120
    onTriggered: Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(ShellState.nightLightTemperature)])
  }

  Process { id: sunset }

  Process {
    id: sunsetCheck
    command: ["bash", "-c", "command -v hyprsunset"]
    running: true
    onExited: (code) => backend.hasSunset = (code === 0)
  }

  Component.onCompleted: refreshQuickControls()
}
