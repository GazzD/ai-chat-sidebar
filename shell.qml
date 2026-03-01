import QtQuick
import Quickshell
import "components/chat"

ShellRoot {
  id: root

  // Toggle manual
  property bool sidebarVisible: true

  ChatSidebar {
    id: sidebar
    visible: root.sidebarVisible
  }
}