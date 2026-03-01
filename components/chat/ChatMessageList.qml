import QtQuick
import QtQuick.Controls
import "."

ScrollView {
  id: root

  property var messages: []
  property bool shouldAutoScroll: true
  property bool isAtBottom: true

  clip: true

  NumberAnimation {
    id: scrollAnimation
    duration: 360
    easing.type: Easing.InOutCubic
    onFinished: {
      root.isAtBottom = true
      root.shouldAutoScroll = true
    }
  }

  Connections {
    target: root.contentItem
    ignoreUnknownSignals: true

    function onContentYChanged() {
      const bottom = Math.max(0, target.contentHeight - root.height)
      root.isAtBottom = target.contentY >= bottom - 10
      root.shouldAutoScroll = root.isAtBottom
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

  function scrollToBottom(force = false, animated = true) {
    Qt.callLater(() => {
      if (!force && !root.shouldAutoScroll) return
      if (root.contentItem) {
        const bottom = Math.max(0, root.contentItem.contentHeight - root.height)
        if (animated) {
          scrollAnimation.stop()
          scrollAnimation.target = root.contentItem
          scrollAnimation.property = "contentY"
          scrollAnimation.from = root.contentItem.contentY
          scrollAnimation.to = bottom
          scrollAnimation.start()
        } else {
          root.contentItem.contentY = bottom
          root.isAtBottom = true
          root.shouldAutoScroll = true
        }
      }
    })
  }
}