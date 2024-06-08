# 1.5.4010 [6/8/2024 10:15:30 AM EST]

[UPDATE]

**File**: lib/peer.dart
**Section**: `Peer` class
**Changes**: Added support for different client types (WebSocket and others)
**Details**: The library now can initialize connections differently based on the client type. For WebSocket clients, it will retrieve a peer ID; for other clients, it won't need an Peer ID using the socketio SID instead.

---


[UPDATE]

**File**: lib/socket.dart
**Section**: `start` function
**Changes**: Added better async handling
**Details**: The connection process now ensures that it waits until the connection is fully established or fails, providing more reliable startup behavior for users.

---

[PATCH]

**File**: lib/socket.dart
**Section**: `start` function
**Changes**: Improved `socketio` URL handling
**Details**: The library now correctly sets the path for `socketio` connections, ensuring they connect to the correct endpoint. the name space is peerjs-socketio



# 1.5.4001

- Initial version.
