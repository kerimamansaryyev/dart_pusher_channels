import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel_mixin.dart';
import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:meta/meta.dart';

typedef EndpointAuthorizationErrorCallback = void Function(
  dynamic exception,
  StackTrace trace,
);

abstract class EndpointAuthorizableChannel<T extends ChannelState,
        A extends EndpointAuthorizationData> extends Channel<T>
    with EndpointAuthorizableChannelMixin<T, A> {
  @protected
  abstract final EndpointAuthorizationErrorCallback? onAuthFailed;
  A? _authData;
  int _authRequestLifeCycle = 0;

  @protected
  A? get authData => _authData;
  @protected
  int get authRequestCycle => _authRequestLifeCycle;

  @protected
  int startNewAuthRequestCycle() => ++_authRequestLifeCycle;

  @protected
  Future<void> setAuthKeyFromDelegate() async {
    final socketId = connectionDelegate.socketId;
    if (socketId == null) {
      return;
    }
    final fixatedLifeCycle = _authRequestLifeCycle;
    A? result;
    try {
      result = await authorizationDelegate.authenticationData(
        socketId,
        name,
      );
      if (fixatedLifeCycle < _authRequestLifeCycle) {
        return;
      }
      _authData = result;
    } catch (exception, trace) {
      if (fixatedLifeCycle < _authRequestLifeCycle) {
        return;
      }
      onAuthFailed?.call(exception, trace);
    }
  }
}
