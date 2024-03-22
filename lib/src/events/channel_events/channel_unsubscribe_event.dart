import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';

/// A data class that represents events with name
/// `pusher:unsubscribe`.
///
/// Instances of this class are used to be sent to a server
/// to unsubscribe from a channel with name [channelName].
///
/// See docs: [Subscription events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events)
class ChannelUnsubscribeEvent
    with PusherChannelsEvent, PusherChannelsSentEventMixin {
  static const eventName = 'pusher:unsubscribe';

  @override
  final String name = eventName;

  final String channelName;

  const ChannelUnsubscribeEvent({
    required this.channelName,
  });

  @override
  String getEncoded() {
    return jsonEncode({
      PusherChannelsEvent.eventNameKey: name,
      PusherChannelsEvent.dataKey: {
        PusherChannelsEvent.channelKey: channelName,
      },
    });
  }
}
