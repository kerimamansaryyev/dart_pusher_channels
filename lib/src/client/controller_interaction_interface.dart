import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:meta/meta.dart';

typedef PusherChannelsClientLifeCycleReconnectDelegate = void Function();
typedef PusherChannelsClientLifeCycleSendEventDelegate = void Function(
  PusherChannelsSentEventMixin event,
);

@immutable
class PusherChannelsClientLifeCycleInteractionInterface {
  @protected
  final PusherChannelsClientLifeCycleReconnectDelegate reconnectDelegate;
  @protected
  final PusherChannelsClientLifeCycleSendEventDelegate sendEventDelegate;

  const PusherChannelsClientLifeCycleInteractionInterface({
    required this.reconnectDelegate,
    required this.sendEventDelegate,
  });

  void reconnect() => reconnectDelegate();
  void sendEvent(PusherChannelsSentEventMixin event) => sendEventDelegate(
        event,
      );
}
