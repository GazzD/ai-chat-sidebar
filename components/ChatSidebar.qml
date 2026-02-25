import QtQuick
import QtQuick.Controls
import Quickshell
import "."

Window {
  id: root
  width: 420
  height: screen.height * 0.7

  property bool isLoading: false
  property string ollamaBaseUrl: "http://localhost:11434"
  property string modelName: "qwen3:8b"
  property string systemPrompt: "Eres un asistente útil y amigable. Responde a las preguntas de los usuarios de manera clara y concisa. Si no sabes la respuesta, di que no lo sabes. Siempre mantén un tono profesional y respetuoso."

  ChatService {
    id: chatService
    ollamaBaseUrl: root.ollamaBaseUrl
    modelName: root.modelName

    onAssistantMessage: (role, content) => {
      const nextMessages = root.messages.slice()
      nextMessages.push({ role: role, content: content })
      root.messages = nextMessages
      chatService.saveMessage(role, content)
    }

    onRequestFailed: (status, errorText) => {
      console.error("ChatService error:", status, errorText)
    }
  }

  x: 0
  y: 0

  Component.onCompleted: {
    x = screen.width - width
    chatService.initializeStorage()
    const persistedMessages = chatService.loadMessages()
    if (persistedMessages.length > 0)
      root.messages = persistedMessages
    scrollToBottom()
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

      // Header
      Text {
        id: headerText
        text: "AI Chat"
        font.pixelSize: 18
        color: "#FFFFFF" 
      }
      
      ChatMessageList {
        id: chatArea
        width: parent.width
        height: parent.height - headerText.height - inputContainer.height - parent.spacing * 2
        messages: root.messages
      }

      ChatInputBox {
        id: inputContainer
        width: parent.width
        isLoading: chatService.isLoading
        onSendMessage: (text) => {
          const nextMessages = root.messages.slice()
          nextMessages.push({ role: "user", content: text })
          root.messages = nextMessages
          chatService.saveMessage("user", text)
          chatService.sendMessage(text, root.messages)
        }
      }
    }
  }

  onMessagesChanged: {
    scrollToBottom()
  }

  function scrollToBottom() {
    chatArea.scrollToBottom()
  }
}