import QtQuick
import QtQuick.Controls
import QtQuick.LocalStorage
import Quickshell
import "."

Window {
  id: root
  width: 420
  height: screen.height * 0.7

  property bool isLoading: false
  property bool shouldAutoScroll: true
  property string ollamaBaseUrl: "http://localhost:11434"
  property string modelName: "qwen3:8b"
  property string systemPrompt: "Eres un asistente útil y amigable. Responde a las preguntas de los usuarios de manera clara y concisa. Si no sabes la respuesta, di que no lo sabes. Siempre mantén un tono profesional y respetuoso."

  x: 0
  y: 0

  Component.onCompleted: {
    x = screen.width - width
    initDb()
    root.messages = root.loadMessages()
    // Scroll to bottom on startup
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
      
      // Chat area
      ScrollView {
        id: chatArea
        width: parent.width
        height: parent.height - headerText.height - inputContainer.height - parent.spacing * 2
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

            Item {
              id: messageRow
              width: messageColumn.width
              height: messageBubble.implicitHeight

              Rectangle {
                id: messageBubble
                width: Math.min(messageRow.width * 0.8, messageText.implicitWidth + 16)
                implicitHeight: messageText.implicitHeight + 16
                height: implicitHeight
                radius: 8
                color: modelData.role === "user" ? "#2a2a2a" : "#1e1e1e"
                anchors.right: modelData.role === "user" ? parent.right : undefined
                anchors.left: modelData.role === "assistant" ? parent.left : undefined

                Text {
                  id: messageText
                  text: modelData.content
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
      }
      // Input area
      Rectangle {
        id: inputContainer
        color: "#222"
        radius: 8
        width: parent.width
        readonly property real minHeight: 40
        readonly property int maxLines: 5
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
                // Shift+Enter: insert newline
                if (event.modifiers & Qt.ShiftModifier) {
                  // Insert newline
                  event.accepted = false
                  return
                }

                // Prevent sending message if currently loading
                if (root.isLoading) {
                  event.accepted = true
                  return
                }

                // Normal enter: send message
                event.accepted = true
                const text = input.text.trim()
                if (text === "") return
                const nextMessages = root.messages.slice()
                nextMessages.push({ role: "user", content: text })
                root.sendMessageToModel(text)
                root.saveMessage("user", text)
                root.messages = nextMessages
                input.text = ""
              }
            }
          }
        }
      }
    }
  }

  onMessagesChanged: {
    // Scroll to bottom when messages change
    scrollToBottom()
  }

  function scrollToBottom() {
    Qt.callLater(() => { // callLater to ensure it runs after the UI updates
      if (!shouldAutoScroll) return
      // Check if contentItem is available before trying to access it
      if (chatArea.contentItem) {
        const bottom = Math.max(0, chatArea.contentItem.contentHeight - chatArea.height)
        chatArea.contentItem.contentY = bottom
      }
    })
  }

  function sendMessageToModel(prompt) {

    root.isLoading = true

    const message = { role: "user", content: prompt }
    console.log("Sending prompt to model:", prompt)
    const xhr = new XMLHttpRequest()
    xhr.open("POST", `${root.ollamaBaseUrl}/api/chat`)
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        root.isLoading = false
        if (xhr.status === 200) {
          const response = JSON.parse(xhr.responseText)
          console.log("Model response:", response)
          // Handle the response from the model here
          const nextMessages = root.messages.slice()
          nextMessages.push({ role: response.message.role, content: response.message.content })
          root.messages = nextMessages
          root.saveMessage(response.message.role, response.message.content) 

        } else {
          console.error("Error from model:", xhr.status, xhr.responseText)
        }
      }
    }

    const requestData = {
      model: root.modelName,
      think: true,
      messages: root.messages.concat({ role: "user", content: prompt }),
      stream: false
    }

    const payload = JSON.stringify(requestData, null, 2)
    console.log("[REQ] POST", root.ollamaBaseUrl + "/api/chat")
    console.log("[REQ] Headers: Content-Type: application/json")
    console.log("[REQ] Body:\n" + payload)

    xhr.send(JSON.stringify(requestData))
  }

  function getDb() {
    return LocalStorage.openDatabaseSync(
      "chat_history",
      "1.0",
      "Chat message history",
      1000000
    )
  }

  function initDb() {
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)"
      )
    })
  }

  function saveMessage(role, content) {
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "INSERT INTO messages (role, content) VALUES (?, ?)",
        [role, content]
      )
    })
  }

  function loadMessages() {
    const db = getDb()
    let messages = []
    db.transaction(function(tx) {
      const rs = tx.executeSql("SELECT role, content FROM messages ORDER BY timestamp ASC")
      for (let i = 0; i < rs.rows.length; i++) {
        const row = rs.rows.item(i)
        messages.push({ role: row.role, content: row.content })
      }
    })
    return messages
  }
}