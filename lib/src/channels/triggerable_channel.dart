import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_trigger_event.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';

/// An interface for channels that can trigger the client events.
/// For present time they are: [PrivateChannel] and [PresenceChannel].
mixin TriggerableChannelMixin<T extends ChannelState> on Channel<T> {
  void trigger(ChannelTriggerEvent event) {
    if (state?.status != ChannelStatus.subscribed) {
      PusherChannelsPackageLogger.log(
        'Attempted to ChannelTriggerEvent "${event.name}" when Channel $name was not subscribed. Ignoring the attempt silently.',
      );
      return;
    }

    connectionDelegate.triggerEvent(event);
  }
}
