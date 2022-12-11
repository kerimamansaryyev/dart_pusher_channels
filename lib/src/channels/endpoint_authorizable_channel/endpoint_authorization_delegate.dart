import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class EndpointAuthorizationData {}

abstract class EndpointAuthorizableChannelAuthorizationDelegate<
    T extends EndpointAuthorizationData> {
  FutureOr<T> authorizationData(String socketId, String channelName);
}
