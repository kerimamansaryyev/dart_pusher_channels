import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';

class ChannelSubscriptionSuccededEvent extends ChannelReadEvent {
  static const eventName = 'pusher_internal:subscription_succeeded';

  ChannelSubscriptionSuccededEvent._({
    required Map<String, dynamic> rootObject,
    required Channel channel,
  }) : super(rootObject: rootObject, channel: channel);

  static ChannelSubscriptionSuccededEvent? tryGetFromChannelReadEvent(
    ChannelReadEvent readEvent,
  ) {
    if (readEvent.name == ChannelSubscriptionSuccededEvent.eventName) {
      return ChannelSubscriptionSuccededEvent._(
        rootObject: readEvent.rootObject,
        channel: readEvent.channel,
      );
    }
    return null;
  }
}
