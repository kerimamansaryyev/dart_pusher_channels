import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';

class ChannelSubscribeEvent
    with PusherChannelsEvent, PusherChannelsSentEventMixin {
  static const eventName = 'pusher:subscribe';

  @override
  final String name = eventName;

  final String channelName;

  final String? channelDataEncoded;

  final String? authKey;

  const ChannelSubscribeEvent({
    required this.channelName,
    required this.authKey,
    required this.channelDataEncoded,
  });

  const ChannelSubscribeEvent.forPublicChannel({
    required String channelName,
  }) : this(
          channelName: channelName,
          authKey: null,
          channelDataEncoded: null,
        );

  const ChannelSubscribeEvent.forPrivateChannel({
    required String channelName,
    required String authKey,
  }) : this(
          channelName: channelName,
          authKey: authKey,
          channelDataEncoded: null,
        );

  const ChannelSubscribeEvent.forPresenceChannel({
    required String channelName,
    required String authKey,
    required String channelDataEncoded,
  }) : this(
          channelName: channelName,
          authKey: authKey,
          channelDataEncoded: channelDataEncoded,
        );

  @override
  String getEncoded() {
    final authorizationKey = authKey;
    final channelData = channelDataEncoded;

    return jsonEncode({
      PusherChannelsEvent.eventNameKey: name,
      PusherChannelsEvent.dataKey: <String, String>{
        PusherChannelsEvent.channelKey: channelName,
        if (authorizationKey != null) 'auth': authorizationKey,
        if (channelData != null) 'channel_data': channelData,
      }
    });
  }
}
