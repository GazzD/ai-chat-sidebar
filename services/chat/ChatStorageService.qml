import QtQuick
import QtQuick.LocalStorage

QtObject {
  id: root

  function initialize() {
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

  function getDb() {
    return LocalStorage.openDatabaseSync(
      "chat_history",
      "1.0",
      "Chat message history",
      1000000
    )
  }
}