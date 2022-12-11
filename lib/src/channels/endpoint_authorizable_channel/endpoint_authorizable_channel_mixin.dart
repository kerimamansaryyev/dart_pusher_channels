import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:meta/meta.dart';

mixin EndpointAuthorizableChannelMixin<T extends ChannelState,
    A extends EndpointAuthorizationData> on Channel<T> {
  @protected
  abstract final EndpointAuthorizableChannelAuthorizationDelegate<A>
      authorizationDelegate;

  @protected
  Future<A?> getAuthKey() {
    final socketId = connectionDelegate.socketId;
    if (socketId == null) {
      return Future.value(null);
    }

    return Future<A>(
      () => authorizationDelegate.authenticationData(socketId, name),
    );
  }
}
