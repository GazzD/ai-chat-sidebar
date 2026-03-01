import QtQuick
import QtQuick.Controls
import "."

// Scrollable conversation list.
// Keeps track of whether the user is reading old messages and only auto-scrolls
// when already near the bottom (unless forced by caller).
ScrollView {
  id: root

  property var messages: []
  // Internal auto-scroll gate toggled by user scrolling position.
  property bool shouldAutoScroll: true
  // Exposed to UI (e.g., show/hide the "scroll to bottom" button).
  property bool isAtBottom: true

  clip: true

  NumberAnimation {
    id: scrollAnimation
    // Smooth scroll when jumping to latest message.
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
      // Track bottom proximity with a small threshold to avoid flickering.
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
      // Respect user scroll position unless an explicit force was requested.
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