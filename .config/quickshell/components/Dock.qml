import Quickshell
import QtQuick

// Per-screen wrapper around DockPanel (adapted from burninc0de.dock-main).
// Theme + app list are passed through so shell.qml owns the palette.
Item {
  id: root

  property color cOnSurface: "#2B4C6F"
  property color cPrimary: "#A7CBEB"
  property color cTrack: "#62829F"
  property color cBg: "#F8FAF9"
  property color cHover: "#A7B3EB"
  property color cMuted: "#62829F"
  property var dockApps: [
    { name: "Chromium", icon: "chromium", cmd: "chromium", appId: "chromium" },
    { name: "Terminal", icon: "foot", cmd: "foot", appId: "foot" },
    { name: "Files", icon: "system-file-manager", cmd: "nautilus", appId: "org.gnome.Nautilus" },
    { name: "Neovim", icon: "nvim", cmd: "foot --app-id=foot-nvim -e nvim", appId: "foot-nvim" }
  ]
  property bool showOnFloating: true
  property bool showRunningApps: true

  Variants {
    model: Quickshell.screens

    DockPanel {
      required property var modelData
      screen: modelData
      cOnSurface: root.cOnSurface
      cPrimary: root.cPrimary
      cTrack: root.cTrack
      cBg: root.cBg
      cHover: root.cHover
      cMuted: root.cMuted
      dockApps: root.dockApps
      showOnFloating: root.showOnFloating
      showRunningApps: root.showRunningApps
    }
  }
}
