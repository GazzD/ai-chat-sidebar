import QtQuick
import QtQuick.Controls
import Quickshell
import "."

Window {
  id: root
  width: 420
  height: screen.height * 0.7

  property bool shouldAutoScroll: true
  x: 0
  y: 0

  Component.onCompleted: x = screen.width - width
  onWidthChanged: x = screen.width - width
  onScreenChanged: x = screen.width - width

  flags: Qt.Tool | Qt.FramelessWindowHint
  color: "#111111"
  opacity: 0.98

  property var messages: [
      { role: "assistant", text: "Hola, ¿en qué te ayudo?" },
      { role: "user", text: "Esto ya pinta bien 😄" }
  ]

  Rectangle {
    anchors.fill: parent
    color: "#111111"

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      // Header
      Text {
        text: "AI Chat"
        font.pixelSize: 18
        color: "#FFFFFF" 
      }
      
      // Chat area
      ScrollView {
        id: chatArea
        width: parent.width
        height: parent.height - 120
        clip: true

        Connections {
          target: chatArea.contentItem
          ignoreUnknownSignals: true

          function onContentYChanged() {
            const bottom = target.contentHeight - chatArea.height
            root.shouldAutoScroll = target.contentY >= bottom - 10
          }
        }

        Column {
          id: messageColumn
          width: chatArea.availableWidth > 0 ? chatArea.availableWidth : chatArea.width
          spacing: 8

          Repeater {
            model: root.messages

            Rectangle {
              width: messageColumn.width
              implicitHeight: messageText.implicitHeight + 16
              height: implicitHeight
              radius: 8
              color: modelData.role === "user" ? "#2a2a2a" : "#1e1e1e"

              Text {
                id: messageText
                text: modelData.text
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
        }
      }
      // Input area
      Rectangle {
        color: "#222"
        radius: 8
        width: parent.width
        height: 40

        TextField {
            id: input
            anchors.fill: parent
            anchors.margins: 8

            placeholderText: "What's on your mind?"
            color: "white"
            background: null  // Prevent TextField from drawing its own background
            font.pixelSize: 14
            onAccepted: {
              console.log("User input:", text)
              if (text.trim() === "") return
              const nextMessages = root.messages.slice()
              nextMessages.push({ role: "user", text: text })
              root.messages = nextMessages
              text = ""
          }
        }
      }
    }
  }

  onMessagesChanged: {
    // Scroll to bottom when messages change
    Qt.callLater(() => { // callLater to ensure it runs after the UI updates
      if (!shouldAutoScroll) return
      // Check if contentItem is available before trying to access it
      if (chatArea.contentItem) {
        const bottom = Math.max(0, chatArea.contentItem.contentHeight - chatArea.height)
        chatArea.contentItem.contentY = bottom
      }
    })
  }
}