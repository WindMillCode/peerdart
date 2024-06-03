import 'dart:typed_data';
import 'package:peerdart/data_connection/buffered_connection/binary_pack_chunker.dart';
import 'supports.dart';
import 'package:peerdart/peerdart-dart-binarypack/binarypack.dart'
    as BinaryPack;

class Util extends BinaryPackChunker {
  void noop() {}

  final String CLOUD_HOST = "0.peerjs.com";
  final int CLOUD_PORT = 443;

  // Browsers that need chunking:
  final Map<String, int> chunkedBrowsers = {"Chrome": 1, "chrome": 1};

  // Returns browser-agnostic default config
  final Map<String, dynamic> defaultConfig = {
    'iceServers': [
      {'urls': "stun:stun.l.google.com:19302"},
      {
        'urls': [
          "turn:eu-0.turn.peerjs.com:3478",
          "turn:us-0.turn.peerjs.com:3478",
        ],
        'username': "peerjs",
        'credential': "peerjsp",
      },
    ],
    'sdpSemantics': "unified-plan",
  };

  late final String browser;
  late final int browserVersion;
  late final Map<String, bool> supports;

  Util() {
    browser = Supports().getBrowser();
    browserVersion = Supports().getVersion();
    supports = {
      'browser': Supports().isBrowserSupported(),
      'webRTC': Supports().isWebRTCSupported(),
      'audioVideo': true,
      'data': true,
      'binaryBlob': true,
      'reliable': true,
    };
  }

  Future<Uint8List> blobToArrayBuffer(Uint8List blob) async {
    return blob;
  }

  Uint8List binaryStringToArrayBuffer(String binary) {
    var byteArray = Uint8List(binary.length);

    for (var i = 0; i < binary.length; i++) {
      byteArray[i] = binary.codeUnitAt(i) & 0xff;
    }

    return byteArray;
  }

  bool isSecure() {
    return true; // Assume secure in Flutter environment
  }

  Future<ByteBuffer> pack(dynamic data) async {
    return BinaryPack.pack(data);
  }

  T unpack<T>(Uint8List data) {
    return BinaryPack.unpack(data);
  }
}

/**
 * Provides a variety of helpful utilities.
 *
 * :::caution
 * Only the utilities documented here are guaranteed to be present on `util`.
 * Undocumented utilities can be removed without warning.
 * We don't consider these to be breaking changes.
 * :::
 */
final util = Util();
