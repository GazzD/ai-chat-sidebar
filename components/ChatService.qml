import QtQuick
import QtQuick.LocalStorage

QtObject {
  id: root

  property bool isLoading: false
  property string ollamaBaseUrl: "http://localhost:11434"
  property string modelName: "qwen3:8b"
  property bool think: true
  property bool debugNetwork: true

  signal assistantMessage(string role, string content)
  signal requestFailed(int status, string errorText)

  function initializeStorage() {
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)"
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

  function saveMessage(role, content) {
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "INSERT INTO messages (role, content) VALUES (?, ?)",
        [role, content]
      )
    })
  }

  function sendMessage(prompt, conversationMessages) {
    root.isLoading = true

    const xhr = new XMLHttpRequest()
    xhr.open("POST", `${root.ollamaBaseUrl}/api/chat`)
    xhr.setRequestHeader("Content-Type", "application/json")

    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return

      root.isLoading = false

      if (xhr.status !== 200) {
        console.error("Error from model:", xhr.status, xhr.responseText)
        root.requestFailed(xhr.status, xhr.responseText)
        return
      }

      try {
        const response = JSON.parse(xhr.responseText)
        if (response.message && response.message.content) {
          root.assistantMessage(response.message.role, response.message.content)
        } else {
          root.requestFailed(xhr.status, "Respuesta inválida: falta message.content")
        }
      } catch (error) {
        root.requestFailed(xhr.status, "No se pudo parsear JSON de respuesta")
      }
    }

    const requestData = {
      model: root.modelName,
      think: root.think,
      messages: conversationMessages,
      stream: false
    }

    if (root.debugNetwork) {
      const payload = JSON.stringify(requestData, null, 2)
      console.log("[REQ] POST", root.ollamaBaseUrl + "/api/chat")
      console.log("[REQ] Headers: Content-Type: application/json")
      console.log("[REQ] Body:\n" + payload)
    }

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
}