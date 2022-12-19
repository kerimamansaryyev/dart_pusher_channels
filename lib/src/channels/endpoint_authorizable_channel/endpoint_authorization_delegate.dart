import 'dart:async';

import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/http_token_authorization_delegate.dart';
import 'package:meta/meta.dart';

typedef EndpointAuthFailedCallback = void Function(
  dynamic exception,
  StackTrace trace,
);

/// An interface for authorization data to be received
/// from by an instance of [EndpointAuthorizableChannel].
@immutable
abstract class EndpointAuthorizationData {}

/// An interface for grabbing an authorization data of type [T]
/// for the channel subscription process.
///
/// See also:
/// - [EndpointAuthorizableChannelTokenAuthorizationDelegate].
abstract class EndpointAuthorizableChannelAuthorizationDelegate<
    T extends EndpointAuthorizationData> {
  /// Added as an option to get a detailed
  /// information about the fail.
  EndpointAuthFailedCallback? get onAuthFailed;

  /// Designed to make an operation to grab the auth data of type [T]
  /// for the channel subscription.
  FutureOr<T> authorizationData(String socketId, String channelName);
}
