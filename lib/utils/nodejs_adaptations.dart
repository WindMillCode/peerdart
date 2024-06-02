import 'dart:convert';
import 'dart:typed_data';

import 'package:events_emitter/events_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerError.dart';

class TextEncoderCommon {
  final String encoding = 'utf-8';
}

class TextEncoder extends TextEncoderCommon {
  Uint8List encode([String input = '']) {
    return utf8.encode(input);
  }

  TextEncoderEncodeIntoResult encodeInto(String source, Uint8List destination) {
    var bytes = utf8.encode(source);
    var length = bytes.length;

    if (destination.length < length) {
      length = destination.length;
    }

    for (var i = 0; i < length; i++) {
      destination[i] = bytes[i];
    }

    return TextEncoderEncodeIntoResult(read: length, written: length);
  }
}

class TextEncoderEncodeIntoResult {
  final int read;
  final int written;

  TextEncoderEncodeIntoResult({required this.read, required this.written});
}


class SubClassEvents<ErrorType> extends EventsWithError<ErrorType> {
  final RTCPeerConnection _peerConnection;

  SubClassEvents(this._peerConnection, {required void Function(PeerError<ErrorType>) error})
    : super(error: error);

  void addEventListener(String event, Function callback) {
    switch (event) {
      case 'onIceCandidate':
        _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
          callback(candidate);
        };
        break;
      case 'onTrack':
        _peerConnection.onTrack = (RTCTrackEvent event) {
          callback(event);
        };
        break;
      case 'onConnectionState':
        _peerConnection.onConnectionState = (RTCPeerConnectionState state) {
          callback(state);
        };
        break;
      // Add more events as needed
      default:
        throw UnimplementedError('Event $event is not supported');
    }
  }

  void removeEventListener(String event) {
    switch (event) {
      case 'onIceCandidate':
        _peerConnection.onIceCandidate = null;
        break;
      case 'onTrack':
        _peerConnection.onTrack = null;
        break;
      case 'onConnectionState':
        _peerConnection.onConnectionState = null;
        break;
      // Add more events as needed
      default:
        throw UnimplementedError('Event $event is not supported');
    }
  }

  void dispatchEvent(String event, dynamic data) {
    switch (event) {
      case 'onIceCandidate':
        _peerConnection.addCandidate(data);
        break;
      // Add more events as needed
      default:
        throw UnimplementedError('Event $event is not supported');
    }
  }
}

typedef ValidEventTypes = dynamic;


class TextDecoderCommon {
  final String encoding;
  final bool fatal;
  final bool ignoreBOM;

  TextDecoderCommon({this.encoding = 'utf-8', this.fatal = false, this.ignoreBOM = false});
}

class TextDecoder extends TextDecoderCommon {
  TextDecoder({String encoding = 'utf-8', bool fatal = false, bool ignoreBOM = false})
      : super(encoding: encoding, fatal: fatal, ignoreBOM: ignoreBOM);

  String decode(Uint8List input, {bool stream = false}) {
    // Since Dart doesn't have a streaming decode, we ignore the `stream` option.
    if (encoding.toLowerCase() == 'utf-8') {
      return utf8.decode(input);
    } else {
      throw UnsupportedError('The encoding $encoding is not supported.');
    }
  }
}


