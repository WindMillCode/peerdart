
import 'package:peerdart/enums.dart';

class ServerMessage {
  // ServerMessageType
  String type;
  dynamic payload;
  String src;

  ServerMessage({
    required this.type,
    required this.payload,
    required this.src,
  });
}
