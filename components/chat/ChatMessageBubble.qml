import QtQuick

// Single chat bubble renderer.
// Assistant messages can be rendered as markdown, user messages remain plain text.
Item {
  id: root

  property string role: "assistant"
  property string content: ""
  // Keep markdown parsing limited to assistant output to avoid accidental formatting.
  readonly property bool markdownEnabled: role === "assistant"

  implicitHeight: bubble.implicitHeight

  Rectangle {
    id: bubble
    // Width is capped for readability and to preserve typical chat bubble proportions.
    width: Math.min(root.width * 0.8, Math.max(180, messageText.implicitWidth + 16))
    implicitHeight: messageText.implicitHeight + 16
    height: implicitHeight
    radius: 8
    color: root.role === "user" ? "#2a2a2a" : "#1e1e1e"
    anchors.right: root.role === "user" ? parent.right : undefined
    anchors.left: root.role === "assistant" ? parent.left : undefined

    Text {
      id: messageText
      text: root.content
      textFormat: root.markdownEnabled ? Text.MarkdownText : Text.PlainText
      color: "#fff"
      font.pixelSize: 14
      wrapMode: Text.Wrap
      width: parent.width - 16
      // Allow clickable links from markdown content.
      onLinkActivated: (link) => Qt.openUrlExternally(link)
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.margins: 8
    }
  }
}