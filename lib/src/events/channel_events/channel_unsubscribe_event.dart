import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';

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
      }
    });
  }
}
