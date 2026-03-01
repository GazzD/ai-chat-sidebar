import QtQuick
import Quickshell
import "components/chat"

// App entrypoint for Quickshell.
// This file only wires top-level visibility/state and mounts the chat sidebar.
ShellRoot {
  id: root

  // Manual toggle for the sidebar window visibility.
  property bool sidebarVisible: true

  ChatSidebar {
    id: sidebar
    visible: root.sidebarVisible
  }
}