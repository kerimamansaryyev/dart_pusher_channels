import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel_mixin.dart';
import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';
import 'package:meta/meta.dart';

typedef EndpointAuthorizationErrorCallback = void Function(
  dynamic exception,
  StackTrace trace,
);

abstract class EndpointAuthorizableChannel<T extends ChannelState,
        A extends EndpointAuthorizationData> extends Channel<T>
    with EndpointAuthorizableChannelMixin<T, A> {
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
      result = await authorizationDelegate.authorizationData(
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
      _handleAuthFailed(exception, trace);
    }
  }

  void _handleAuthFailed(dynamic exception, StackTrace trace) {
    if (currentStatus == ChannelStatus.unsubscribed) {
      return;
    }

    late final String message;

    final defaultMessage = '''
Failed to get authorizationData.
Channel: $name,
Exception: $exception,
Trace: $trace,
        ''';

    if (exception is PusherChannelsException) {
      message = exception.message;
    } else {
      message = defaultMessage;
    }

    PusherChannelsPackageLogger.log(
      message,
    );

    publicEventEmitter(
      ChannelReadEvent.forSubscriptionError(
        this,
        type: Channel.authErrorTypeString,
        errorMessage: message,
      ),
    );
    Future.microtask(
      () => authorizationDelegate.onAuthFailed?.call(
        exception,
        trace,
      ),
    );
  }
}
