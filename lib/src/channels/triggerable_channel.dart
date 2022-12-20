import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_trigger_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';

/// An interface for channels that can trigger the client events.
/// For present time they are: [PrivateChannel] and [PresenceChannel].
mixin TriggerableChannelMixin<T extends ChannelState> on Channel<T> {
  /// Be careful with [data].
  ///
  /// In some cases pusher accepts double encoded data as [String], in others - [Map]
  /// that will be encoded within the root object in [PusherChannelsSentEventMixin.getEncoded].
  ///
  /// See the implementation of: [ChannelTriggerEvent].
  void trigger({
    required String eventName,
    required dynamic data,
  }) {
    final event = ChannelTriggerEvent(
      channel: this,
      name: eventName,
      data: data,
    );
    if (state?.status != ChannelStatus.subscribed) {
      PusherChannelsPackageLogger.log(
        'Attempted to ChannelTriggerEvent "${event.name}" when Channel $name was not subscribed. Ignoring the attempt silently.',
      );
      return;
    }

    connectionDelegate.triggerEvent(event);
  }
}
