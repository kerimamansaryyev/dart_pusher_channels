part of channels;

class PusherAuthenticationException extends PusherException {
  final int statusCode;
  PusherAuthenticationException({required this.statusCode}) : super();
}

abstract class AuthorizationDelegate {
  FutureOr<String> authenticationString(String socketId, String channelName);
}

class TokenAuthorizationDelegate extends AuthorizationDelegate {
  final Uri authorizationEndpoint;
  final Map<String, String> headers;

  TokenAuthorizationDelegate(
      {required this.authorizationEndpoint,
      required this.headers,
      FutureOr<String> Function(http.Response response) parser =
          defaultAuthCodeParser})
      : _parser = parser;

  final FutureOr<String> Function(http.Response response) _parser;

  @override
  Future<String> authenticationString(
      String socketId, String channelName) async {
    var response = await http.post(authorizationEndpoint,
        headers: headers,
        body: jsonEncode({'socket_id': socketId, 'channel': channelName}));
    print(response.body);
    if (response.statusCode != 200) {
      throw PusherAuthenticationException(statusCode: response.statusCode);
    }
    return _parser(response);
  }
}

FutureOr<String> defaultAuthCodeParser(http.Response response) {
  var decoded = jsonDecode(response.body);
  var auth = decoded['auth'] ?? "";
  return auth;
}
