import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:windmillcode_peerdart/baseconnection.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/binary_pack.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/json.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/raw.dart';
import 'package:windmillcode_peerdart/media_connection.dart';
import 'package:windmillcode_peerdart/option_interfaces.dart';
import 'package:windmillcode_peerdart/peer_error.dart';
import 'package:windmillcode_peerdart/util.dart';
import 'package:windmillcode_peerdart/logger.dart';
import 'package:windmillcode_peerdart/socket.dart';
import 'package:windmillcode_peerdart/data_connection/data_connection.dart';
import 'package:windmillcode_peerdart/enums.dart';
import 'package:windmillcode_peerdart/servermessage.dart';
import 'package:windmillcode_peerdart/api.dart';
import 'package:windmillcode_peerdart/utils/random_token.dart';

class PeerOptions implements PeerJSOption {
  // LogLevel
  late LogLevel? debug;
  late String? host;
  late int? port;
  late String? path;
  late String? key;
  late String? token;
  late dynamic config;
  late bool? secure;
  late int? pingInterval;
  late String? referrerPolicy;
  // "websocket" | "socketio"
  String clientType;
  late void Function(LogLevel logLevel, dynamic args)? logFunction;
  late Map<String, DataConnection Function(String peerId, Peer provider, dynamic options)> serializers;

  PeerOptions({
    LogLevel? debug,
    String? host,
    int? port,
    this.path = "/",
    String? key,
    String? token,
    dynamic config,
    this.secure = true,
    this.pingInterval,
    String? referrerPolicy,
    this.logFunction,
    this.clientType = "websocket",
    Map<String, DataConnection Function(String peerId, Peer provider, dynamic options)>? serializers,
  })  : debug = debug ?? LogLevel.Disabled,
        port = port ?? util.CLOUD_PORT,
        host = host ?? util.CLOUD_HOST,
        key = key ?? Peer.DEFAULT_KEY,
        token = token ?? randomToken(),
        config = config ?? util.defaultConfig,
        referrerPolicy = referrerPolicy ?? "strict-origin-when-cross-origin",
        serializers = serializers ?? <String, DataConnection Function(String peerId, Peer provider, dynamic options)>{};
}

typedef DataConnectionConstructor = DataConnection Function(String peerId, Peer provider, dynamic options);

class SerializerMapping {
  final Map<String, DataConnectionConstructor> _mapping;

  SerializerMapping(this._mapping);

  DataConnectionConstructor? operator [](String key) => _mapping[key];
}

class PeerEvents<ErrorType extends String> extends EventsWithError<ErrorType> {
  final void Function(String id)? open;
  final void Function(DataConnection dataConnection)? connection;
  final void Function(MediaConnection mediaConnection)? call;
  final void Function()? close;
  final void Function(String currentId)? disconnected;
  final void Function(PeerError<String> error)? error;

  PeerEvents({
    this.open,
    this.connection,
    this.call,
    this.close,
    this.disconnected,
    this.error,
  }) : super(error: error);
}

// PeerErrorType
class Peer extends EventEmitterWithError<String, PeerEvents> {
  static const String DEFAULT_KEY = 'peerjs';
  Map<String, DataConnection Function(String peerId, Peer provider, dynamic options)> _serializers = {
    'raw': (String peerId, Peer provider, dynamic options) {
      return Raw(peerId, provider, options);
    },
    'json': (String peerId, Peer provider, dynamic options) {
      return Json(peerId, provider, options);
    },
    'binary': (String peerId, Peer provider, dynamic options) {
      return BinaryPack(peerId, provider, options);
    },
    'binary-utf8': (String peerId, Peer provider, dynamic options) {
      return BinaryPack(peerId, provider, options);
    },
    'default': (peerId, provider, options) {
      return BinaryPack(peerId, provider, options);
    }
  };
  final PeerOptions _options;
  final API _api;
  final Socket _socket;
  Socket get socket => _socket;

  String? _id;
  String? _lastServerId;
  bool _destroyed = false;
  bool _disconnected = false;
  bool _open = false;
  final Map<String, List<BaseConnection>> _connections = {};
  final Map<String, List<ServerMessage>> _lostMessages = {};

  Peer({String? id, PeerOptions? options})
      : _options = options ?? PeerOptions(),
        _api = API(options ?? PeerOptions()),
        _socket = Socket(
          options?.secure ?? util.isSecure(),
          options?.host ?? util.CLOUD_HOST,
          options?.port ?? util.CLOUD_PORT,
          options?.path ?? '/',
          options?.key ?? DEFAULT_KEY,
          clientType: options?.clientType ?? "websocket",
          pingInterval: options?.pingInterval ?? 5000,
        ) {
    _serializers = {..._serializers, ..._options.serializers};
    _options.host = _options.host == '/' ? 'localhost' : _options.host;
    _options.path = _options.path?.startsWith('/') ?? false ? _options.path : '/${_options.path}';
    _options.path = _options.path?.endsWith('/') ?? false ? _options.path : '${_options.path}/';
    logger.logLevel = _options.debug ?? LogLevel.Disabled;
    if (_options.logFunction != null) {
      logger.setLogFunction(_options.logFunction!);
    }
  }

  String? get id => _id;
  PeerOptions get options => _options;
  bool get open => _open;
  bool get destroyed => _destroyed;
  bool get disconnected => _disconnected;
  Map<String, List<BaseConnection>> get connections => _connections;
  bool isInit = false;

  Future<void> init([String? id]) async {
    if (isInit == true) {
      return;
    }
    isInit = true;
    if (id != null) {
      await _initialize(id);
    } else {
      if (options.clientType == "websocket") {
        try {
          String id = await _api.retrieveId();
          await _initialize(id);
        } catch (error, stack) {
          _abort(PeerErrorType.ServerError, error);
        }
      } else {
        await _initialize();
      }
    }

    _socket.on(SocketEventType.Message.value, (Map data) {
      _handleMessage(ServerMessage(
          type: data["type"], payload: PeerConnectOption.fromJson(data["payload"] ?? {}), src: data["src"]));
    });

    _socket.on(SocketEventType.Error.value, (error) => _abort(PeerErrorType.SocketError, error));

    _socket.on(SocketEventType.Disconnected.value, (data) {
      if (_disconnected) return;
      emitError(PeerErrorType.Network.value, 'Lost connection to server.');
      disconnect();
    });

    _socket.on(SocketEventType.Close.value, (data) {
      if (_disconnected) return;
      _abort(PeerErrorType.SocketClosed, 'Underlying socket is already closed.');
    });
  }

  Future<void> _initialize([String? id]) async {
    if (options.clientType == "websocket") {
      _id = id;
      await _socket.start(id!, _options.token!);
    } else {
      await _socket.start(id, _options.token!);
      _id = _socket.socketio!.id;
    }
  }

  void _handleMessage(ServerMessage message) {
    final type = message.type;
    final payload = message.payload as PeerConnectOption;
    final peerId = message.src;

    if (type == ServerMessageType.Open.value) {
      _lastServerId = id;
      _open = true;
      emit('open', id);
    } else if (type == ServerMessageType.Error.value) {
      _abort(PeerErrorType.ServerError, payload.msg);
    } else if (type == ServerMessageType.IdTaken.value) {
      _abort(PeerErrorType.UnavailableID, 'ID "$id" is taken');
    } else if (type == ServerMessageType.InvalidKey.value) {
      _abort(PeerErrorType.InvalidKey, 'API KEY "${_options.key}" is invalid');
    } else if (type == ServerMessageType.Leave.value) {
      logger.log('Received leave message from $peerId');
      _cleanupPeer(peerId!);
      _connections.remove(peerId);
    } else if (type == ServerMessageType.Expire.value) {
      emitError(PeerErrorType.PeerUnavailable.value, 'Could not connect to peer $peerId');
    } else if (type == ServerMessageType.Offer.value) {
      final connectionId = payload.connectionId;
      var connection = getConnection(peerId!, connectionId!);

      if (connection != null) {
        connection.close();
        logger.warn('Offer received for existing Connection ID:$connectionId');
      }

      if (payload.type == ConnectionType.Media.value) {
        final mediaConnection = MediaConnection(
            peerId,
            this,
            PeerConnectOption.fromJson({
              'connectionId': connectionId,
              'payload': payload,
              'metadata': payload.metadata,
            }));
        connection = mediaConnection;
        _addConnection(peerId, connection);
        emit('call', mediaConnection);
      } else if (payload.type == ConnectionType.Data.value) {
        final dataConnection = _serializers[payload.serialization]!(
          peerId,
          this,
          PeerConnectOption.fromJson({
            'connectionId': connectionId,
            'payload': payload,
            'metadata': payload.metadata,
            'label': payload.label,
            'serialization': payload.serialization,
            'reliable': payload.reliable,
          }),
        );
        connection = dataConnection;
        _addConnection(peerId, connection);
        emit('connection', dataConnection);
      } else {
        logger.warn('Received malformed connection type:${payload.type}');
        return;
      }

      final messages = getMessages(connectionId);
      for (final message in messages) {
        connection.handleMessage(message);
      }
    } else {
      if (payload == null) {
        logger.warn('You received a malformed message from $peerId of type $type');
        return;
      }

      final connectionId = payload.connectionId!;
      final connection = getConnection(peerId!, connectionId);

      if (connection != null && connection.peerConnection != null) {
        connection.handleMessage(message);
      } else if (connectionId != null) {
        _storeMessage(connectionId, message);
      } else {
        logger.warn('You received an unrecognized message: $message');
      }
    }
  }

  void _storeMessage(String connectionId, ServerMessage message) {
    if (!_lostMessages.containsKey(connectionId)) {
      _lostMessages[connectionId] = [];
    }
    _lostMessages[connectionId]!.add(message);
  }

  List<ServerMessage> getMessages(String connectionId) {
    final messages = _lostMessages[connectionId];
    if (messages != null) {
      _lostMessages.remove(connectionId);
      return messages;
    }
    return [];
  }

  DataConnection? connect(String peer, [PeerConnectOption? options]) {
    options ??= PeerConnectOption();
    if (_disconnected) {
      logger.warn(
          'You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect.');
      emitError(PeerErrorType.Disconnected.value, 'Cannot connect to new Peer after disconnecting from server.');
      return null;
    }

    final dataConnection = _serializers[options.serialization ?? 'default']!(peer, this, options);
    _addConnection(peer, dataConnection);
    return dataConnection;
  }

  MediaConnection? call(String peer, MediaStream? stream, [CallOption? options]) {
    options ??= CallOption();
    if (_disconnected) {
      logger.warn(
          'You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect.');
      emitError(PeerErrorType.Disconnected.value, 'Cannot connect to new Peer after disconnecting from server.');
      return null;
    }

    if (stream == null) {
      logger.error("To call a peer, you must provide a stream from your browser's `getUserMedia`.");
      return null;
    }

    final mediaConnection = MediaConnection(peer, this, <String, dynamic>{
      ...options.toMap(),
      '_stream': stream,
    });

    _addConnection(peer, mediaConnection);
    return mediaConnection;
  }

  void _addConnection(String peerId, BaseConnection connection) {
    logger.log('add connection ${connection.type}:${connection.connectionId} to peerId:$peerId');

    if (!_connections.containsKey(peerId)) {
      _connections[peerId] = [];
    }
    _connections[peerId]!.add(connection);
  }

  // DataConnection
  void removeConnection(dynamic connection) {
    final connections = _connections[connection.peer];
    if (connections != null) {
      connections.remove(connection);
    }
    _lostMessages.remove(connection.connectionId);
  }

  BaseConnection? getConnection(String peerId, String connectionId) {
    final connections = _connections[peerId];
    if (connections != null) {
      for (final connection in connections) {
        if (connection.connectionId == connectionId) {
          return connection;
        }
      }
    }
    return null;
  }

  void _delayedAbort(PeerErrorType type, dynamic message) {
    Future.delayed(Duration.zero, () {
      _abort(type, message);
    });
  }

  void _abort(PeerErrorType type, dynamic message) {
    logger.error('Aborting!');
    emitError(type.value, message);
    if (_lastServerId == null) {
      destroy();
    } else {
      disconnect();
    }
  }

  void destroy() {
    if (_destroyed) return;

    logger.log('Destroy peer with ID:$id');
    disconnect();
    _cleanup();
    _destroyed = true;
    emit('close');
  }

  void _cleanup() {
    _connections.forEach((peerId, _) {
      _cleanupPeer(peerId);
    });
    _connections.clear();
    _socket.off();
  }

  void _cleanupPeer(String peerId) {
    final connections = _connections[peerId];
    if (connections != null) {
      for (final connection in connections) {
        connection.close();
      }
    }
  }

  void disconnect() {
    if (_disconnected) return;

    final currentId = id;
    logger.log('Disconnect peer with ID:$currentId');

    _disconnected = true;
    _open = false;
    _socket.close();
    _lastServerId = currentId;
    _id = null;
    emit('disconnected', currentId);
  }

  void reconnect() async {
    if (_disconnected && !_destroyed) {
      logger.log('Attempting reconnection to server with ID $_lastServerId');
      _disconnected = false;
      await _initialize(_lastServerId!);
    } else if (_destroyed) {
      throw Exception('This peer cannot reconnect to the server. It has already been destroyed.');
    } else if (!_disconnected && !_open) {
      logger.error('In a hurry? We\'re still trying to make the initial connection!');
    } else {
      throw Exception('Peer $id cannot reconnect because it is not disconnected from the server!');
    }
  }

  void listAllPeers(Function(List<dynamic>) cb) {
    _api.listAllPeers().then((peers) => cb(peers)).catchError((error) => _abort(PeerErrorType.ServerError, error));
  }
}
