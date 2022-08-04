part of channels;

/// Exception that is supposed to be thrown when [AuthorizationDelegate] fails to
/// get auth string
/// It is recommended to create separate implementations for each [AuthorizationDelegate]
abstract class PusherAuthenticationException extends PusherException {}

/// Exception thrown when [TokenAuthorizationDelegate] fails to get auth String
class PusherTokenAuthDelegateException extends PusherAuthenticationException {
  /// response got from [http.post] method
  final http.Response response;

  PusherTokenAuthDelegateException._(this.response);
}

/// Special interface designed to return auth string with [authenticationString]
/// Used by [PrivateChannel] to get auth string to subscribe
abstract class AuthorizationDelegate {
  /// The method to get auth string from server by [PrivateChannel]
  FutureOr<String> authenticationString(String socketId, String channelName);
}

/// Implementation of [AuthorizationDelegate] through http protocol
@immutable
class TokenAuthorizationDelegate implements AuthorizationDelegate {
  final FutureOr<String> Function(http.Response response) _parser;
  final Uri authorizationEndpoint;
  final Map<String, String> headers;

  const TokenAuthorizationDelegate({
    required this.authorizationEndpoint,
    required this.headers,

    /// Provide custom parse method, otherwise [defaultAuthCodeParser] will be used
    FutureOr<String> Function(http.Response response) parser =
        defaultAuthCodeParser,
  }) : _parser = parser;

  @override
  Future<String> authenticationString(
    String socketId,
    String channelName,
  ) async {
    final response = await http.post(
      authorizationEndpoint,
      headers: {
        ...headers,
        'content-type': 'application/x-www-form-urlencoded'
      },
      body: {'socket_id': socketId, 'channel_name': channelName},
    );

    if (response.statusCode != 200) {
      throw PusherTokenAuthDelegateException._(response);
    }
    return _parser(response);
  }
}

FutureOr<String> defaultAuthCodeParser(http.Response response) {
  final decoded = jsonDecode(response.body);
  return decoded['auth'] ?? '';
}
