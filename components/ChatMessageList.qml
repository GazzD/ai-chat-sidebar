import QtQuick
import QtQuick.Controls
import "."

ScrollView {
  id: root

  property var messages: []
  property bool shouldAutoScroll: true

  clip: true

  Connections {
    target: root.contentItem
    ignoreUnknownSignals: true

    function onContentYChanged() {
      const bottom = target.contentHeight - root.height
      root.shouldAutoScroll = target.contentY >= bottom - 10
    }
  }

  Column {
    id: messageColumn
    width: root.availableWidth > 0 ? root.availableWidth : root.width
    spacing: 8

    Repeater {
      model: root.messages

      ChatMessageBubble {
        width: messageColumn.width
        role: modelData.role
        content: modelData.content
      }
    }
  }

  function scrollToBottom() {
    Qt.callLater(() => {
      if (!root.shouldAutoScroll) return
      if (root.contentItem) {
        const bottom = Math.max(0, root.contentItem.contentHeight - root.height)
        root.contentItem.contentY = bottom
      }
    })
  }
}