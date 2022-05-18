part of channels;

abstract class AuthorizationDelegate {
  FutureOr<String> authenticationString();
}

class TokenAuthorizationDelegate extends AuthorizationDelegate {
  final Uri authorizationEndpoint;
  final Map<String, String> headers;

  TokenAuthorizationDelegate(
      {required this.authorizationEndpoint, required this.headers});

  @override
  FutureOr<String> authenticationString() {
    return '';
  }
}
