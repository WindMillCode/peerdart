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


# 1.5.4030 [10/3/2024 2:22:33 PM EST]

[UPDATE] updated packages to reflect the latest version of flutter
 `http` bumped from 1.2.1 to 1.2.2 in pubspec.yaml
 `flutter_webrtc` bumped from 0.11.2 to 0.11.7 in pubspec.yaml
 `socket_io_client` bumped from 2.0.3+1 to 3.0.0 in pubspec.yaml
 `web_socket_channel` bumped from 3.0.0 to 3.0.1 in pubspec.yaml
 `lints` bumped from 4.0.0 to 5.0.0 in pubspec.yaml
 `build_runner` bumped from 2.4.11 to 2.4.13 in pubspec.yaml

[BUG] - potential andriod issue where if the andriod device is the receiver may have issues on negotiation step in the webrtc connection setup

# 1.5.4031 
