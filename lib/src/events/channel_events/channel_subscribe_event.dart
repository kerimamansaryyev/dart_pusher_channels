import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';

class ChannelSubscribeEvent
    with PusherChannelsEvent, PusherChannelsSentEventMixin {
  static const eventName = 'pusher:subscribe';

  @override
  final String name = eventName;

  final String channelName;

  const ChannelSubscribeEvent({
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
