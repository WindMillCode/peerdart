import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:events_emitter/events_emitter.dart';

import 'logger.dart';
import 'enums.dart';
import 'version.dart';

/// An abstraction on top of WebSockets to provide the fastest
/// possible connection for peers.
class Socket extends EventEmitter {
  bool _disconnected = true;
  String? _id;
  final List<Map<String, dynamic>> _messagesQueue = [];
  WebSocketChannel? _socket;
  late Timer _wsPingTimer;
  final String _baseUrl;
  final int pingInterval;

  Socket(
    bool secure,
    String host,
    int port,
    String path,
    String key, {
    this.pingInterval = 5000,
  }) : _baseUrl = '${secure ? 'wss://' : 'ws://'}$host:$port${path}peerjs?key=$key';

  Future<void> start(String id, String token) async {
    _id = id;
    final version = await getVersion();
    final wsUrl = '$_baseUrl&id=$id&token=$token';

    if (_socket != null || !_disconnected) {
      return;
    }

    _socket = WebSocketChannel.connect(Uri.parse(wsUrl + "&version=$version"),
        protocols: ["websocket"]);
    _disconnected = false;
    logger.log('WebSocket connection established.');

    _socket!.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        logger.log('Server message received: $data');
        emit(SocketEventType.Message.value, data);
      } catch (err, stack) {
        logger.log('Invalid server message $message');
      }
    }, onError: (err) {
      logger.error(err.inner.message);
    }, onDone: () {
      if (_disconnected) {
        return;
      }

      logger.log('Socket closed.');
      _cleanup();
      _disconnected = true;
      emit(SocketEventType.Disconnected.value);
    });

    _socket!.sink
        .addStream(Stream.fromIterable([
      jsonEncode({'type': 'open'})
    ]))
        .then((_) {
      if (_disconnected) {
        return;
      }
      _sendQueuedMessages();
      logger.log('Socket open');
      _scheduleHeartbeat();
    }).catchError((error) {
      logger.log('Error opening socket: $error');
    });
  }

  void _scheduleHeartbeat() {
    _wsPingTimer = Timer(Duration(milliseconds: pingInterval), _sendHeartbeat);
  }

  void _sendHeartbeat() {
    if (!_wsOpen()) {
      logger.log('Cannot send heartbeat, because socket closed');
      return;
    }

    final message = jsonEncode({'type': ServerMessageType.Heartbeat.value});
    _socket!.sink.add(message);
    _scheduleHeartbeat();
  }

  bool _wsOpen() {
    return _socket != null && _socket!.closeCode == null;
  }

  void _sendQueuedMessages() {
    final copiedQueue = List<Map<String, dynamic>>.from(_messagesQueue);
    _messagesQueue.clear();

    for (final message in copiedQueue) {
      send(message);
    }
  }

  void send(Map<String, dynamic> data) {
    if (_disconnected) {
      return;
    }

    if (_id == null) {
      _messagesQueue.add(data);
      return;
    }

    if (!data.containsKey('type')) {
      emit(SocketEventType.Error.value, 'Invalid message');
      return;
    }

    if (!_wsOpen()) {
      return;
    }

    final message = jsonEncode(data);
    _socket!.sink.add(message);
  }

  void close() {
    if (_disconnected) {
      return;
    }

    _cleanup();
    _disconnected = true;
  }

  void _cleanup() {
    _socket?.sink.close();
    _socket = null;
    _wsPingTimer.cancel();
  }
}
