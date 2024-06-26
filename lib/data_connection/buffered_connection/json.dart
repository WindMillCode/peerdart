import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/buffered_connection.dart';
import 'package:windmillcode_peerdart/enums.dart';
import 'package:windmillcode_peerdart/util.dart';
import 'package:windmillcode_peerdart/utils/nodejs_adaptations.dart';

class Json extends BufferedConnection {
  @override
  final String serialization = SerializationType.JSON.value;
  final TextEncoder encoder = TextEncoder();
  final TextDecoder decoder = TextDecoder();

  Json(super.peerId, super.provider, super.options);

  String stringify(dynamic data) => jsonEncode(data);
  dynamic parse(String data) => jsonDecode(data);

  @override
  void handleDataMessage(RTCDataChannelMessage message) {
    final deserializedData = parse(decoder.decode(message.binary));

    // PeerJS specific message
    final peerData = deserializedData['__peerData'];
    if (peerData != null && peerData['type'] == 'close') {
      close();
      return;
    }

    emit('data', deserializedData);
  }

  @override
  Future<void> privateSend(dynamic data, [bool chunked = false]) async {
    final encodedData = encoder.encode(stringify(data));
    if (encodedData.length >= util.chunkedMTU) {
      emitError(DataConnectionErrorType.MessageToBig.value, 'Message too big for JSON channel');
      return;
    }
    bufferedSend(encodedData);
  }
}
