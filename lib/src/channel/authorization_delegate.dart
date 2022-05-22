part of channels;

abstract class PusherAuthenticationException extends PusherException {}

class PusherTokenAuthDelegateException extends PusherAuthenticationException {
  final http.Response response;

  PusherTokenAuthDelegateException._(this.response);
}

abstract class AuthorizationDelegate {
  FutureOr<String> authenticationString(String socketId, String channelName);
}

@immutable
class TokenAuthorizationDelegate implements AuthorizationDelegate {
  final Uri authorizationEndpoint;
  final Map<String, String> headers;

  const TokenAuthorizationDelegate(
      {required this.authorizationEndpoint,
      required this.headers,
      FutureOr<String> Function(http.Response response) parser =
          defaultAuthCodeParser})
      : _parser = parser;

  final FutureOr<String> Function(http.Response response) _parser;

  @override
  Future<String> authenticationString(
      String socketId, String channelName) async {
    var response = await http.post(authorizationEndpoint, headers: {
      ...headers,
      'content-type': 'application/x-www-form-urlencoded'
    }, body: {
      'socket_id': socketId,
      'channel_name': channelName
    });

    if (response.statusCode != 200) {
      throw PusherTokenAuthDelegateException._(response);
    }
    return _parser(response);
  }
}

FutureOr<String> defaultAuthCodeParser(http.Response response) {
  var decoded = jsonDecode(response.body);
  var auth = decoded['auth'] ?? "";
  return auth;
}
