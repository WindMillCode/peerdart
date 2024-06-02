import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:events_emitter/events_emitter.dart';

import 'logger.dart';
import 'enums.dart';
import 'version.dart';

/**
 * An abstraction on top of WebSockets to provide the fastest
 * possible connection for peers.
 */
class Socket extends EventEmitter {
  bool _disconnected = true;
  String? _id;
  final List<Map<String, dynamic>> _messagesQueue = [];
  WebSocket? _socket;
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
  }) : _baseUrl = '${secure ? 'wss://' : 'ws://'}$host:$port$path?key=$key';

  void start(String id, String token) async {
    _id = id;
    final version = await getVersion();
    final wsUrl = '$_baseUrl&id=$id&token=$token&version=$version';

    if (_socket != null || !_disconnected) {
      return;
    }

    _socket = WebSocket(wsUrl);
    _disconnected = false;

    _socket!.onMessage.listen((event) {
      try {
        final data = jsonDecode(event.data);
        logger.log('Server message received: $data');
        emit(SocketEventType.Message.value, data);
      } catch (e) {
        logger.log('Invalid server message ${event.data}');
      }
    });

    _socket!.onClose.listen((event) {
      if (_disconnected) {
        return;
      }

      logger.log('Socket closed. $event' );
      _cleanup();
      _disconnected = true;
      emit(SocketEventType.Disconnected.value);
    });

    _socket!.onOpen.listen((event) {
      if (_disconnected) {
        return;
      }

      _sendQueuedMessages();
      logger.log('Socket open');
      _scheduleHeartbeat();
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
    _socket!.send(message);
    _scheduleHeartbeat();
  }

  bool _wsOpen() {
    return _socket != null && _socket!.readyState == WebSocket.OPEN;
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
    _socket!.send(message);
  }

  void close() {
    if (_disconnected) {
      return;
    }

    _cleanup();
    _disconnected = true;
  }

  void _cleanup() {
    _socket?.onOpen.listen(null);
    _socket?.onMessage.listen(null);
    _socket?.onClose.listen(null);
    _socket?.close();
    _socket = null;
    _wsPingTimer.cancel();
  }
}
