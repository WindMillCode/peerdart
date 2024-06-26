import 'package:windmillcode_peerdart/logger.dart';
import 'package:json_annotation/json_annotation.dart';


part 'option_interfaces.g.dart';

enum RTCBundlePolicy {
  balanced,
  maxBundle,
  maxCompat,
}

extension RTCBundlePolicyExtension on RTCBundlePolicy {
  String get value {
    switch (this) {
      case RTCBundlePolicy.balanced:
        return 'balanced';
      case RTCBundlePolicy.maxBundle:
        return 'max-bundle';
      case RTCBundlePolicy.maxCompat:
        return 'max-compat';
    }
  }
}

enum RTCIceTransportPolicy {
  all,
  relay,
}

extension RTCIceTransportPolicyExtension on RTCIceTransportPolicy {
  String get value {
    switch (this) {
      case RTCIceTransportPolicy.all:
        return 'all';
      case RTCIceTransportPolicy.relay:
        return 'relay';
    }
  }
}

enum RTCRtcpMuxPolicy {
  require,
}

extension RTCRtcpMuxPolicyExtension on RTCRtcpMuxPolicy {
  String get value {
    switch (this) {
      case RTCRtcpMuxPolicy.require:
        return 'require';
    }
  }
}

class RTCDtlsFingerprint {
  String? algorithm;
  String? value;

  RTCDtlsFingerprint({this.algorithm, this.value});
}

class RTCIceServer {
  String? credential;
  List<String> urls;
  String? username;

  RTCIceServer({required this.urls, this.credential, this.username});
}

abstract class RTCCertificate {
  int get expires;
  List<RTCDtlsFingerprint> getFingerprints();
}

abstract class RTCConfiguration {
  RTCBundlePolicy? bundlePolicy;
  List<RTCCertificate>? certificates;
  int? iceCandidatePoolSize;
  List<RTCIceServer>? iceServers;
  RTCIceTransportPolicy? iceTransportPolicy;
  RTCRtcpMuxPolicy? rtcpMuxPolicy;
}

class AnswerOption {
  /// Function which runs before create answer to modify sdp answer message.
  Function? sdpTransform;
  dynamic payload;
  AnswerOption({this.sdpTransform, this.payload});
}

class PeerJSOption {
  String? key;
  String? host;
  int? port;
  String? path;
  bool? secure;
  String? token;
  // RTCConfiguration
  dynamic config;
  LogLevel? debug;
  String? referrerPolicy;

  PeerJSOption({
    this.key,
    this.host,
    this.port,
    this.path,
    this.secure,
    this.token,
    this.config,
    this.debug,
    this.referrerPolicy,
  });
}

@JsonSerializable()
class PeerConnectOption {
  /// A unique label by which you want to identify this data connection.
  /// If left unspecified, a label will be generated at random.
  ///
  /// Can be accessed with {@apilink DataConnection.label}
  String? label;

  /// Metadata associated with the connection, passed in by whoever initiated the connection.
  ///
  /// Can be accessed with {@apilink DataConnection.metadata}.
  /// Can be any serializable type.
  dynamic metadata;

  String? serialization;
  bool? reliable;
  String? connectionId;
  dynamic payload;
  Map<String, dynamic> constraints;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Function(String sdp)? sdpTransform;
  Map<String, String> sdp;
  String? type;
  dynamic msg;
  Map? candidate;

  PeerConnectOption(
      {this.label,
      this.metadata,
      this.serialization,
      this.reliable,
      this.connectionId,
      this.payload,
      this.sdpTransform,
      Map<String, String>? sdp,
      Map<String, dynamic>? constraints,
      this.type,
      this.msg,
      this.candidate})
      : sdp = sdp ?? {},
        constraints = constraints ??
            {
              "mandatory": {"OfferToReceiveAudio": true, "OfferToReceiveVideo": true},
              "optional": [
                {"DtlsSrtpKeyAgreement": true},
                {"googImprovedWifiBwe": true}
              ]
            };

  factory PeerConnectOption.fromJson(Map<String, dynamic> json) => _$PeerConnectOptionFromJson(json);
  Map<String, dynamic> toJson() => _$PeerConnectOptionToJson(this);
}

class CallOption {
  /// Metadata associated with the connection, passed in by whoever initiated the connection.
  ///
  /// Can be accessed with {@apilink MediaConnection.metadata}.
  /// Can be any serializable type.
  dynamic metadata;

  /// Function which runs before create offer to modify sdp offer message.
  Function? sdpTransform;

  CallOption({
    this.metadata,
    this.sdpTransform,
  });

  Map<String, dynamic> toMap() {
    return {
      'metadata': metadata,
      'sdpTransform': sdpTransform,
    };
  }
}
