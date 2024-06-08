# Windmillcode PeerDart: Simple peer-to-peer with WebRTC

PeerDart provides a complete, configurable, and easy-to-use peer-to-peer API built on top of WebRTC, supporting both data channels and (planned) media streams.

PeerDart **mirrors** the design of peerjs. Find the documentation [here](https://peerjs.com/docs).

* supports socketio connections
* sends chunks based on maxMessageSize from local and remote session descriptions


## Status

- [x] Alpha: Under heavy development
- [x] Public Alpha: Ready for testing. But go easy on us, there will be bugs and missing functionality.
- [x] Public Beta: Stable. No breaking changes expected in this version but possible bugs. (media is public alpha)
- [ ] Public: Production-ready

## Setup


**Create a Peer**

```dart
<!-- for development -->
final Peer peer = Peer(options:PeerOptions(
      // debug: LogLevel.All,
));
<!-- for production -->
final Peer peer = Peer(options:PeerOptions(
      // debug: LogLevel.All,
      clientType: "socketio",
      host: "[YOUR SERVER DOMAIN]",
      port: 9000,
      secure: true));

```

## Data connections

**Connect**

```dart
var peer;
if (peer?.id == null) {
    peer = Peer(options: APPENV.peerdart);
    wait peer!.init();
}

var conn = webrtc.connect(res.data.result["sender_peer_id"]);
conn.on("open",(data) async {
    conn.send("hi!");
})
```

**Receive**

```dart
if (peer?.id == null) {
    peer = Peer(options: APPENV.peerdart);
    wait peer!.init();
}
peer!.on("connection", (DataConnection? conn) {
    conn?.on("data", (dynamic data) async {
        <!-- work with your data -->
    })
})
```



## Support
Works on android

## Reference
| Property        | Type                                                                      | Default Value                          | Description                                                                 |
|-----------------|---------------------------------------------------------------------------|----------------------------------------|-----------------------------------------------------------------------------|
| `debug`         | `LogLevel?`                                                               | `LogLevel.Disabled`                    | Log level for debugging.                                                    |
| `host`          | `String?`                                                                 | `util.CLOUD_HOST`                      | Host address of the PeerServer.                                             |
| `port`          | `int?`                                                                    | `util.CLOUD_PORT`                      | Port on which the PeerServer is running.                                    |
| `path`          | `String?`                                                                 | `"/"`                                  | Path to the PeerServer.                                                     |
| `key`           | `String?`                                                                 | `Peer.DEFAULT_KEY`                     | API key for the PeerServer.                                                 |
| `token`         | `String?`                                                                 | `randomToken()`                        | Token used for authentication.                                              |
| `config`        | `dynamic`                                                                 | `util.defaultConfig`                   | Configuration options for the RTC connection.                               |
| `secure`        | `bool?`                                                                   | `true`                                 | Whether the connection should be secure (https/wss).                        |
| `pingInterval`  | `int?`                                                                    | `null`                                 | Interval for sending ping messages to keep the connection alive.            |
| `referrerPolicy`| `String?`                                                                 | `"strict-origin-when-cross-origin"`    | Referrer policy for the HTTP requests.                                      |
| `clientType`    | `"websocket" \| "socketio"`                                               | `"websocket"`                          | Type of client to use for the connection.                                   |
| `logFunction`   | `void Function(LogLevel logLevel, dynamic args)?`                         | `null`                                 | Custom log function.                                                        |
| `serializers`   | `Map<String, DataConnection Function(String peerId, Peer provider, dynamic options)>` | `{}`                                   | Custom serializers for different data connection types.                     |



## Links

### [Documentation / API Reference](https://peerjs.com/docs/)

### [PeerServer](https://github.com/Judimax/peerjs-server/tree/PR-socketio-support)

## License

PeerDart is licensed under the [MIT License](./LICENSE).
