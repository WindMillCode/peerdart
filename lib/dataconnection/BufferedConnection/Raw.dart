// FileName: raw.dart

import 'dart:typed_data';
import 'package:events_emitter/events_emitter.dart';
import 'package:peerdart/dataconnection/BufferedConnection/BufferedConnection.dart';
import 'package:peerdart/enums.dart';

class Raw extends BufferedConnection {
  @override
  final String serialization = SerializationType.None.value;

  Raw(super.peerId, super.provider, super.options);
  // SerializationType
  void _handleDataMessage({required dynamic data}) {
    super.emit('data', data);
  }

  void _send(dynamic data, bool chunked) {
    bufferedSend(data);
  }
}
