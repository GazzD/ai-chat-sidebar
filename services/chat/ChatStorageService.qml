import QtQuick
import QtQuick.LocalStorage

// Persistence layer for chat history.
// Encapsulates SQLite operations so UI components stay storage-agnostic.
QtObject {
  id: root

  function initialize() {
    // Creates schema once (idempotent).
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)"
      )
    })
  }

  function loadMessages() {
    // Returns messages ordered by creation timestamp for deterministic replay.
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
    // Simple append-only persistence for conversation turns.
    const db = getDb()
    db.transaction(function(tx) {
      tx.executeSql(
        "INSERT INTO messages (role, content) VALUES (?, ?)",
        [role, content]
      )
    })
  }

  function getDb() {
    // Shared local database handle for this feature scope.
    return LocalStorage.openDatabaseSync(
      "chat_history",
      "1.0",
      "Chat message history",
      1000000
    )
  }
}