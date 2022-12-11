import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class EndpointAuthorizationData {}

abstract class EndpointAuthorizableChannelAuthorizationDelegate<
    T extends EndpointAuthorizationData> {
  FutureOr<T> authenticationData(String socketId, String channelName);
}
