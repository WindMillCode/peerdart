import 'dart:convert';
import 'dart:typed_data';
import 'package:events_emitter/events_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/dataconnection/BufferedConnection/BufferedConnection.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/logger.dart';
import 'package:peerdart/util.dart';
import 'package:peerdart/utils/nodejs_adaptations.dart';

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
  void send(dynamic data, {bool chunked = false}) {
    final encodedData = encoder.encode(stringify(data));
    if (encodedData.length >= util.chunkedMTU) {
      emitError(DataConnectionErrorType.MessageToBig.value, 'Message too big for JSON channel');
      return;
    }
    bufferedSend(encodedData);
  }
}
