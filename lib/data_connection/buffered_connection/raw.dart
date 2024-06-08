// FileName: raw.dart

import 'package:windmillcode_peerdart/data_connection/buffered_connection/buffered_connection.dart';
import 'package:windmillcode_peerdart/enums.dart';

class Raw extends BufferedConnection {
  @override
  final String serialization = SerializationType.None.value;

  Raw(super.peerId, super.provider, super.options);
  // SerializationType
  void _handleDataMessage({required dynamic data}) {
    super.emit('data', data);
  }

  Future<void> privateSend(dynamic data, bool chunked) async {
    bufferedSend(data);
  }
}
