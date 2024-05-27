enum ConnectionType {
  Data("data"),
  Media("media");

  const ConnectionType(this.type);
  final String type;
}

enum ServerMessageType {
  Heartbeat("HEARTBEAT"),
  Candidate("CANDIDATE"),
  Offer("OFFER"),
  Answer("ANSWER"),
  Open("OPEN"),
  Error("ERROR"),
  IdTaken("ID-TAKEN"),
  InvalidKey("INVALID-KEY"),
  Leave("LEAVE"),
  Expire("EXPIRE");

  const ServerMessageType(this.type);
  final String type;
}

enum SocketEventType {
  Message("message"),
  Disconnected("disconnected"),
  Error("error"),
  Close("close");

  const SocketEventType(this.type);
  final String type;
}

enum PeerErrorType {
  BrowserIncompatible("browser-incompatible"),
  Disconnected("disconnected"),
  InvalidID("invalid-id"),
  InvalidKey("invalid-key"),
  Network("network"),
  PeerUnavailable("peer-unavailable"),
  SslUnavailable("ssl-unavailable"),
  ServerError("server-error"),
  SocketError("socket-error"),
  SocketClosed("socket-closed"),
  UnavailableID("unavailable-id"),
  WebRTC("webrtc");

  const PeerErrorType(this.type);
  final String type;
}

enum SerializationType {
  Binary("binary"),
  JSON("json");

  const SerializationType(this.type);
  final String type;
}

enum LogLevel {
  Disabled(3),
  Errors(2),
  Warnings(1),
  All(0);

  const LogLevel(this.level);
  final int level;
}

enum PeerEventListener {
  open("open"),
  close("close"),
  stream("stream"),
  connection("connection"),
  call("call"),
  data("data");

  final String event;
  const PeerEventListener(this.event);
}

enum DataChannels { binary, data }
