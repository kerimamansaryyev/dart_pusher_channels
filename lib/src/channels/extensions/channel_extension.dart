import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';

extension ChannelExtension<T extends ChannelState> on Channel<T> {
  Stream<ChannelReadEvent> whenSubscriptionSucceeded() =>
      bind(Channel.subscriptionSucceededEventName);

  Stream<ChannelReadEvent> whenSubscriptionCount() => bind(
        Channel.subscriptionsCountEventName,
      );

  Stream<ChannelReadEvent> onSubscriptionError({String? errorType}) =>
      bind(Channel.subscriptionErrorEventName).where(
        (event) => _filterSubscriptionErrorPredicate(errorType, event),
      );

  Stream<ChannelReadEvent> onAuthenticationSubscriptionFailed() =>
      onSubscriptionError(
        errorType: Channel.authErrorType,
      );

  bool _filterSubscriptionErrorPredicate(
    String? errorType,
    ChannelReadEvent event,
  ) {
    if (errorType == null) {
      return true;
    }
    final eventErrorType =
        event.tryGetDataAsMap()?[PusherChannelsEvent.errorTypeKey]?.toString();

    return eventErrorType == errorType;
  }
}
