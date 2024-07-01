# 1.5.4020 [6/12/2024 11:45:22 AM EST]

[UPDATE] Added dart:async import in binary_pack.dart and data_connection.dart.

[FIX] Improved logging message clarity in binary_pack.dart.

[UPDATE] Modified _handleChunk method in binary_pack.dart for better variable handling.

[UPDATE] privateSend method in binary_pack.dart now handles OutOfMemoryError and retries after a delay.

[UPDATE] Adjusted logging in _sendChunks method in binary_pack.dart.

[PATCH] BufferedConnection in buffered_connection.dart now uses a dynamic message and logs errors with stack traces.

[PATCH] DataConnection maxBufferedAmount updated to MAX_BUFFERED_AMOUNT in data_connection.dart, stream_connection.dart, and buffered_connection.dart.

[FIX] Socket class in socket.dart now properly cancels the _wsPingTimer when closing the WebSocket connection.

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

# 1.5.4021
* UPDATED dependencies
