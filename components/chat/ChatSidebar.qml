import QtQuick
import QtQuick.Controls
import Quickshell
import "."
import "../../services/chat"

Window {
  id: root
  width: 420
  height: screen.height * 0.7

  property string ollamaBaseUrl: "http://localhost:11434"
  property string modelName: "qwen3:8b"
  property string systemPrompt: "Eres un asistente útil y amigable. Responde a las preguntas de los usuarios de manera clara y concisa. Si no sabes la respuesta, di que no lo sabes. Siempre mantén un tono profesional y respetuoso."
  property bool debugNetwork: false

  ChatStorageService {
    id: storageService
  }

  OllamaChatService {
    id: modelService
    ollamaBaseUrl: root.ollamaBaseUrl
    modelName: root.modelName
    systemPrompt: root.systemPrompt
    debugNetwork: root.debugNetwork

    onAssistantMessage: (role, content) => {
      const nextMessages = root.messages.slice()
      nextMessages.push({ role: role, content: content })
      root.messages = nextMessages
      storageService.saveMessage(role, content)
    }

    onRequestFailed: (status, errorText) => {
      console.error("OllamaChatService error:", status, errorText)
    }
  }

  x: 0
  y: 0

  Component.onCompleted: {
    x = screen.width - width
    storageService.initialize()
    const persistedMessages = storageService.loadMessages()
    if (persistedMessages.length > 0)
      root.messages = persistedMessages
    scrollToBottom(true)
  }
  onWidthChanged: x = screen.width - width
  onScreenChanged: x = screen.width - width

  flags: Qt.Tool | Qt.FramelessWindowHint
  color: "#111111"
  opacity: 0.98

  property var messages: [
      { role: "assistant", content: "Hola, ¿en qué te ayudo?" },
      { role: "user", content: "Esto ya pinta bien 😄" },
      { role: "assistant", content: "¡Me alegra que te guste! Si tienes alguna pregunta o necesitas ayuda, no dudes en decírmelo." },
      { role: "user", content: "¿Puedes contarme un chiste?" },
      { role: "assistant", content: "¡Claro! Aquí tienes uno:\n\n¿Por qué los programadores confunden Halloween con Navidad?\n\nPorque OCT 31 es igual a DEC 25." }
  ]

  Rectangle {
    anchors.fill: parent
    color: "#111111"

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Text {
        id: headerText
        text: "AI Chat"
        font.pixelSize: 18
        color: "#FFFFFF"
      }

      Item {
        id: chatContainer
        width: parent.width
        height: parent.height - headerText.height - inputContainer.height - parent.spacing * 2

        ChatMessageList {
          id: chatArea
          anchors.fill: parent
          messages: root.messages
        }

        Rectangle {
          id: scrollToBottomButton
          visible: !chatArea.isAtBottom
          width: 32
          height: 32
          radius: 16
          color: "#222"
          border.color: "#3a3a3a"
          opacity: scrollButtonMouse.containsMouse ? 1.0 : 0.9
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 12

          Text {
            anchors.centerIn: parent
            text: "↓"
            color: "#fff"
            font.pixelSize: 16
          }

          MouseArea {
            id: scrollButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.scrollToBottom(true, true)
          }
        }
      }

      ChatInputBox {
        id: inputContainer
        width: parent.width
        isLoading: modelService.isLoading
        onSendMessage: (text) => {
          const nextMessages = root.messages.slice()
          nextMessages.push({ role: "user", content: text })
          root.messages = nextMessages
          storageService.saveMessage("user", text)
          modelService.sendMessage(root.messages)
          root.scrollToBottom(true, true)
        }
      }
    }
  }

  onMessagesChanged: {
    scrollToBottom()
  }

  function scrollToBottom(force = false, animated = true) {
    chatArea.scrollToBottom(force, animated)
  }
}