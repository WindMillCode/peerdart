class ServerMessage {
  // ServerMessageType
  String type;
  dynamic payload;
  String? src;
  String? dst;

  ServerMessage({
    required this.type,
    this.payload,
    this.src,
    this.dst
  });
}
