// FileName: raw.dart

import 'package:peerdart/data_connection/buffered_connection/buffered_connection.dart';
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
