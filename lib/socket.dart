import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'logger.dart';
import 'enums.dart';
import 'version.dart';

/// An abstraction on top of WebSockets to provide the fastest
/// possible connection for peers.
class Socket extends EventEmitter {
  bool _disconnected = true;
  String? _id;
  final List<Map<String, dynamic>> _messagesQueue = [];
  WebSocketChannel? _websocket;
  IO.Socket? _socketio;
  late Timer _wsPingTimer;
  final String _baseWebSocketUrl;
  final String _baseSocketioUrl;
  final Map<String, dynamic> _baseSocketioQueryParams;
  final String clientType;
  final int pingInterval;

  Socket(
    bool secure,
    String host,
    int port,
    String path,
    String key, {
    this.clientType = 'websocket',
    this.pingInterval = 5000,
  })  : _baseWebSocketUrl = '${secure ? 'wss://' : 'ws://'}$host:$port${path}peerjs?key=$key',
        _baseSocketioUrl = '${secure ? 'wss://' : 'ws://'}$host:$port',
        _baseSocketioQueryParams = {'key': key};

  Future<void> start(String id, String token) async {
    _id = id;
    final version = await getVersion();
    final wsUrl = '$_baseWebSocketUrl&id=$id&token=$token';

    if ((_websocket != null || _socketio != null) || !_disconnected) {
      return;
    }

    if (clientType == 'websocket') {
      _websocket = WebSocketChannel.connect(Uri.parse(wsUrl + "&version=$version"), protocols: ["websocket"]);
    } else {
      _socketio = IO.io(
        _baseSocketioUrl,
        IO.OptionBuilder()
            .setQuery({..._baseSocketioQueryParams, 'id': id, 'token': token, 'version': version}).build(),
      );
    }
    _disconnected = false;
    logger.log('WebSocket connection established.');

    if (clientType == 'websocket') {
      _websocket!.stream.listen((message) {
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

      _websocket!.sink
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
    } else {
      _socketio!.on('connect', (_) {
        if (_disconnected) {
          return;
        }
        _sendQueuedMessages();
        logger.log('Socket open');
      });

      _socketio!.on('message', (data) {
        try {
          logger.log(
            'Server message received:$data',
          );
          emit(SocketEventType.Message.value, data);
        } catch (e) {
          logger.log('Invalid server message $data');
        }
      });

      _socketio!.on('error', (err) {
        logger.error('$err');
      });

      _socketio!.on('disconnect', (reason) {
        if (_disconnected) {
          return;
        }
        logger.log('Socket closed.$reason');
        _cleanup();
        _disconnected = true;
        emit(SocketEventType.Disconnected.value);
      });
    }
  }

  void _scheduleHeartbeat() {
    _wsPingTimer = Timer(Duration(milliseconds: pingInterval), _sendHeartbeat);
  }

  void _sendHeartbeat() {
    if (!_wsOpen()) {
      logger.log('Cannot send heartbeat, because socket closed');
      return;
    }

    if (clientType == 'websocket') {
      final message = jsonEncode({'type': ServerMessageType.Heartbeat.value});
      _websocket!.sink.add(message);
      _scheduleHeartbeat();
    }
  }

  bool _wsOpen() {
    if (clientType == 'websocket') {
      return _websocket != null && _websocket!.closeCode == null;
    } else {
      return _socketio != null && _socketio!.connected;
    }
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
    if (clientType == 'websocket') {
      _websocket!.sink.add(message);
    } else {
      _socketio!.emit('message', message);
    }
  }

  void close() {
    if (_disconnected) {
      return;
    }

    _cleanup();
    _disconnected = true;
  }

  void _cleanup() {
    if (clientType == 'websocket') {
      _websocket?.sink.close();
      _websocket = null;
    } else {
      _socketio?.disconnect();
      _socketio?.close();
      _socketio?.dispose();
      _socketio?.destroy();
      _socketio = null;
    }
    _wsPingTimer.cancel();
  }
}