import 'dart:math';

import 'package:peerdart/version.dart';

import 'util.dart';
import 'logger.dart';
import 'option_interfaces.dart';
import 'package:http/http.dart' as http;

class API {
  final PeerJSOption _options;

  API(this._options);

  Future<http.Response> _buildRequest(String method) async {
    final protocol = _options.secure == true ? "https" : "http";
    final host = _options.host;
    final port = _options.port;
    final path = _options.path;
    final key = _options.key;
    final url = Uri.parse('$protocol://$host:$port$path$key/$method');

    final updatedUrl = url.replace(queryParameters: {
      'ts': '${DateTime.now().millisecondsSinceEpoch}${Random().nextDouble()}',
      'version': await getVersion(),
    });
    print(updatedUrl);

    return await http.get(updatedUrl, headers: {
      'referrerPolicy': _options.referrerPolicy ?? '',
    });
  }

  /// Get a unique ID from the server via HTTP and initialize with it.
  Future<String> retrieveId() async {
    try {
      final response = await _buildRequest('id');

      if (response.statusCode != 200) {
        throw Exception('Error. Status:${response.statusCode}');
      }

      return response.body;
    } catch (err, stack) {
      logger.error('Error retrieving ID $err');

      String pathError = '';

      if (_options.path == '/' && _options.host != util.CLOUD_HOST) {
        pathError = " If you passed in a `path` to your self-hosted PeerServer, "
            "you'll also need to pass in that same path when creating a new "
            "Peer.";
      }

      throw Exception('Could not get an ID from the server. $pathError');
    }
  }

  /// @deprecated
  Future<List<dynamic>> listAllPeers() async {
    try {
      final response = await _buildRequest('peers');

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          String helpfulError = '';

          if (_options.host == util.CLOUD_HOST) {
            helpfulError = "It looks like you're using the cloud server. You can email " +
                "team@peerjs.com to enable peer listing for your API key.";
          } else {
            helpfulError =
                "You need to enable `allow_discovery` on your self-hosted " + "PeerServer to use this feature.";
          }

          throw Exception("It doesn't look like you have permission to list peers IDs. " + helpfulError);
        }

        throw Exception('Error. Status:${response.statusCode}');
      }

      return List<dynamic>.from(response.body as List<dynamic>);
    } catch (error) {
      logger.error('Error retrieving list p $error');

      throw Exception('Could not get list peers from the server. $error');
    }
  }
}
