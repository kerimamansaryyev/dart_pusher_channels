import 'dart:async';

import 'package:meta/meta.dart';

typedef EndpointAuthFailedCallback = void Function(
  dynamic exception,
  StackTrace trace,
);

@immutable
abstract class EndpointAuthorizationData {}

abstract class EndpointAuthorizableChannelAuthorizationDelegate<
    T extends EndpointAuthorizationData> {
  abstract final EndpointAuthFailedCallback? onAuthFailed;
  FutureOr<T> authorizationData(String socketId, String channelName);
}
