import QtQuick
import QtQuick.Controls

// Multiline message composer.
// Grows until a max line count, then switches to internal scrolling.
Rectangle {
  id: root

  property bool isLoading: false
  // Emitted when a valid message should be sent upstream.
  signal sendMessage(string message)

  color: "#222"
  radius: 8

  readonly property real minHeight: 40
  readonly property int maxLines: 5
  // Approximate line height used to cap auto-growth.
  readonly property real lineHeight: input.font.pixelSize * 1.35
  readonly property real maxHeight: lineHeight * maxLines + 16
  height: Math.max(minHeight, Math.min(maxHeight, input.contentHeight + 16))

  ScrollView {
    id: inputScroll
    anchors.fill: parent
    anchors.margins: 8
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    TextArea {
      id: input
      width: inputScroll.availableWidth > 0 ? inputScroll.availableWidth : inputScroll.width
      height: Math.max(inputScroll.availableHeight, contentHeight)

      placeholderText: "What's on your mind?"
      color: "white"
      background: null
      font.pixelSize: 14
      wrapMode: TextEdit.Wrap
      topPadding: 0
      bottomPadding: 0
      leftPadding: 0
      rightPadding: 0

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          // Shift+Enter inserts newline (default TextArea behavior).
          if (event.modifiers & Qt.ShiftModifier) {
            event.accepted = false
            return
          }

          // While waiting for model response, consume Enter to avoid duplicate sends.
          if (root.isLoading) {
            event.accepted = true
            return
          }

          // Enter sends message when non-empty.
          event.accepted = true
          const message = input.text.trim()
          if (message === "") return
          root.sendMessage(message)
          input.text = ""
        }
      }
    }
  }
}