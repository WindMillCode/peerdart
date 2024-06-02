import 'dart:async';
import 'dart:convert';
import 'package:events_emitter/events_emitter.dart';

import 'logger.dart';
import 'enums.dart';
import 'version.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// An abstraction on top of WebSockets to provide the fastest
/// possible connection for peers.
class Socket extends EventEmitter {
  bool _disconnected = true;
  String? _id;
  final List<Map<String, dynamic>> _messagesQueue = [];
  IO.Socket? _socket;
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
  }) : _baseUrl = '${secure ? 'https://' : 'http://'}$host:$port$path?key=$key';

  Future<void> start(String id, String token) async {
    _id = id;
    final version = await getVersion();
    final wsUrl = '$_baseUrl&id=$id&token=$token&version=$version';

    if (_socket != null || !_disconnected) {
      return;
    }

    _socket = IO.io(
        wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    _disconnected = false;
    logger.log('WebSocket connection established.');

    _socket!.on('connect', (_) {
      logger.log('Socket connected');
      _disconnected = false;
      _sendQueuedMessages();
      _scheduleHeartbeat();
    });

    _socket!.on('message', (message) {
      try {
        final data = jsonDecode(message);
        logger.log('Server message received: $data');
        emit(SocketEventType.Message.value, data);
      } catch (e) {
        logger.log('Invalid server message $message');
      }
    });

    _socket!.on('disconnect', (_) {
      if (_disconnected) {
        return;
      }

      logger.log('Socket closed.');
      _cleanup();
      _disconnected = true;
      emit(SocketEventType.Disconnected.value);
    });

    _socket!.on('error', (error) {
      emit(SocketEventType.Error.value, error);
    });

    _socket!.connect();
    _sendQueuedMessages();
    logger.log('Socket open');
    _scheduleHeartbeat();
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
    _socket!.emit('message', message);
    _scheduleHeartbeat();
  }

  bool _wsOpen() {
    return _socket != null;
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
    _socket!.emit('message', message);
  }

  void close() {
    if (_disconnected) {
      return;
    }

    _cleanup();
    _disconnected = true;
  }

  void _cleanup() {
    _socket?.disconnect();
    _socket?.close();
    _socket?.dispose();
    _socket?.destroy();
    _socket = null;
    _wsPingTimer.cancel();
  }
}
