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

/// A base class for channels that require authorization before subscription.
///
/// Exposes internal members for setting an auth data of type [A].
///
/// See also:
/// - [Authorizing docs](https://pusher.com/docs/channels/server_api/authorizing-users/).
abstract class EndpointAuthorizableChannel<T extends ChannelState,
    A extends EndpointAuthorizationData> extends Channel<T> {
  @protected
  abstract final EndpointAuthorizableChannelAuthorizationDelegate<A>
      authorizationDelegate;

  A? _authData;
  int _authRequestLifeCycle = 0;

  /// Current authorization data of this channel.
  @protected
  A? get authData => _authData;

  /// Gives a current lifecycle of a request made to an endpoint.
  @protected
  int get authRequestCycle => _authRequestLifeCycle;

  /// Increases the lifecycle count before making request to
  /// block changes made from the old request.
  @protected
  int startNewAuthRequestCycle() => ++_authRequestLifeCycle;

  /// Sets a new lifecycle, tries to make request to get
  /// the auth data of type [A].
  ///
  /// The fails are handled by [_handleAuthFailed] which in its order
  /// emits the channel subscription error using the [publicEventEmitter].
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
      message = 'Channel: $name\nException:${exception.message}\nTrace:$trace';
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
