import QtQuick

QtObject {
  id: root

  property bool isLoading: false
  property string ollamaBaseUrl: "http://localhost:11434"
  property string modelName: "qwen3:8b"
  property string systemPrompt: ""
  property bool think: true
  property bool debugNetwork: true

  signal assistantMessage(string role, string content)
  signal requestFailed(int status, string errorText)

  function sendMessage(conversationMessages) {
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

    const messagesForRequest = root.systemPrompt.trim() !== ""
      ? [{ role: "system", content: root.systemPrompt }].concat(conversationMessages)
      : conversationMessages

    const requestData = {
      model: root.modelName,
      think: root.think,
      messages: messagesForRequest,
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
}