enum ConnectionType {
  Data,
  Media,
}

extension ConnectionTypeExtension on ConnectionType {
  String get value {
    switch (this) {
      case ConnectionType.Data:
        return "data";
      case ConnectionType.Media:
        return "media";
    }
  }
}

enum PeerErrorType {
  BrowserIncompatible,
  Disconnected,
  InvalidID,
  InvalidKey,
  Network,
  PeerUnavailable,
  SslUnavailable,
  ServerError,
  SocketError,
  SocketClosed,
  UnavailableID,
  WebRTC,
}

extension PeerErrorTypeExtension on PeerErrorType {

  String get value {
    switch (this) {
      case PeerErrorType.BrowserIncompatible:
        return "browser-incompatible";
      case PeerErrorType.Disconnected:
        return "disconnected";
      case PeerErrorType.InvalidID:
        return "invalid-id";
      case PeerErrorType.InvalidKey:
        return "invalid-key";
      case PeerErrorType.Network:
        return "network";
      case PeerErrorType.PeerUnavailable:
        return "peer-unavailable";
      case PeerErrorType.SslUnavailable:
        return "ssl-unavailable";
      case PeerErrorType.ServerError:
        return "server-error";
      case PeerErrorType.SocketError:
        return "socket-error";
      case PeerErrorType.SocketClosed:
        return "socket-closed";
      case PeerErrorType.UnavailableID:
        return "unavailable-id";
      case PeerErrorType.WebRTC:
        return "webrtc";
    }
  }
}

enum BaseConnectionErrorType {
  NegotiationFailed,
  ConnectionClosed,
}

extension BaseConnectionErrorTypeExtension on BaseConnectionErrorType {
  String get value {
    switch (this) {
      case BaseConnectionErrorType.NegotiationFailed:
        return "negotiation-failed";
      case BaseConnectionErrorType.ConnectionClosed:
        return "connection-closed";
    }
  }
}

enum DataConnectionErrorType {
  NotOpenYet,
  MessageToBig,
}

extension DataConnectionErrorTypeExtension on DataConnectionErrorType {
  String get value {
    switch (this) {
      case DataConnectionErrorType.NotOpenYet:
        return "not-open-yet";
      case DataConnectionErrorType.MessageToBig:
        return "message-too-big";
    }
  }
}

enum SerializationType {
  Binary,
  BinaryUTF8,
  JSON,
  None,
}

extension SerializationTypeExtension on SerializationType {
  String get value {
    switch (this) {
      case SerializationType.Binary:
        return "binary";
      case SerializationType.BinaryUTF8:
        return "binary-utf8";
      case SerializationType.JSON:
        return "json";
      case SerializationType.None:
        return "raw";
    }
  }
}

enum SocketEventType {
  Message,
  Disconnected,
  Error,
  Close,
}

extension SocketEventTypeExtension on SocketEventType {
  String get value {
    switch (this) {
      case SocketEventType.Message:
        return "message";
      case SocketEventType.Disconnected:
        return "disconnected";
      case SocketEventType.Error:
        return "error";
      case SocketEventType.Close:
        return "close";
    }
  }
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

extension ServerMessageTypeExtension on ServerMessageType {
  String get value {
    switch (this) {
      case ServerMessageType.Heartbeat:
        return "HEARTBEAT";
      case ServerMessageType.Candidate:
        return "CANDIDATE";
      case ServerMessageType.Offer:
        return "OFFER";
      case ServerMessageType.Answer:
        return "ANSWER";
      case ServerMessageType.Open:
        return "OPEN";
      case ServerMessageType.Error:
        return "ERROR";
      case ServerMessageType.IdTaken:
        return "ID-TAKEN";
      case ServerMessageType.InvalidKey:
        return "INVALID-KEY";
      case ServerMessageType.Leave:
        return "LEAVE";
      case ServerMessageType.Expire:
        return "EXPIRE";
    }
  }
}
