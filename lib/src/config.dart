const _DEFAULT_CONFIG = {
  'iceServers': [
    {'urls': "stun:stun.bethesda.net:3478"},
    {
      "urls": [
        "turn:eu-0.turn.peerjs.com:3478",
        "turn:us-0.turn.peerjs.com:3478",
      ],
      "username": "peerjs",
      "credential": "peerjsp",
    },
  ],
  'sdpSemantics': "unified-plan"
};

class PeerConfig {
  static const String CLOUD_HOST = "0.peerjs.com";
  static const int CLOUD_PORT = 443;
  static const Map<String, dynamic> defaultConfig = _DEFAULT_CONFIG;
  static const String DEFAULT_KEY = "peerjs";
  static const String VERSION = "1.0";
}
