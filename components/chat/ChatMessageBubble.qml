import QtQuick

Item {
  id: root

  property string role: "assistant"
  property string content: ""

  implicitHeight: bubble.implicitHeight

  Rectangle {
    id: bubble
    width: Math.min(root.width * 0.8, messageText.implicitWidth + 16)
    implicitHeight: messageText.implicitHeight + 16
    height: implicitHeight
    radius: 8
    color: root.role === "user" ? "#2a2a2a" : "#1e1e1e"
    anchors.right: root.role === "user" ? parent.right : undefined
    anchors.left: root.role === "assistant" ? parent.left : undefined

    Text {
      id: messageText
      text: root.content
      color: "#fff"
      font.pixelSize: 14
      wrapMode: Text.Wrap
      width: parent.width - 16
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.margins: 8
    }
  }
}