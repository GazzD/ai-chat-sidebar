import QtQuick
import Quickshell
import "components"

ShellRoot {
  id: root

  // Toggle manual
  property bool sidebarVisible: true

  ChatSidebar {
    id: sidebar
    visible: root.sidebarVisible
  }
}