enum ConnectionType {
  Data,
  Media,
}

enum PeerErrorType {
  /// The client's browser does not support some or all WebRTC features that you are trying to use.
  BrowserIncompatible,

  /// You've already disconnected this peer from the server and can no longer make any new connections on it.
  Disconnected,

  /// The ID passed into the Peer constructor contains illegal characters.
  InvalidID,

  /// The API key passed into the Peer constructor contains illegal characters or is not in the system (cloud server only).
  InvalidKey,

  /// Lost or cannot establish a connection to the signalling server.
  Network,

  /// The peer you're trying to connect to does not exist.
  PeerUnavailable,

  /// PeerJS is being used securely, but the cloud server does not support SSL. Use a custom PeerServer.
  SslUnavailable,

  /// Unable to reach the server.
  ServerError,

  /// An error from the underlying socket.
  SocketError,

  /// The underlying socket closed unexpectedly.
  SocketClosed,

  /// The ID passed into the Peer constructor is already taken.
  ///
  /// This error is not fatal if your peer has open peer-to-peer connections.
  /// This can happen if you attempt to reconnect a peer that has been disconnected from the server,
  /// but its old ID has now been taken.
  UnavailableID,

  /// Native WebRTC errors.
  WebRTC,
}

enum BaseConnectionErrorType {
  NegotiationFailed,
  ConnectionClosed,
}

enum DataConnectionErrorType {
  NotOpenYet,
  MessageToBig,
}

enum SerializationType {
  Binary,
  BinaryUTF8,
  JSON,
  None,
}

enum SocketEventType {
  Message,
  Disconnected,
  Error,
  Close,
}

enum ServerMessageType {
  Heartbeat,
  Candidate,
  Offer,
  Answer,
  Open, // The connection to the server is open.
  Error, // Server error.
  IdTaken, // The selected ID is taken.
  InvalidKey, // The given API key cannot be found.
  Leave, // Another peer has closed its connection to this peer.
  Expire, // The offer sent to a peer has expired without response.
}
