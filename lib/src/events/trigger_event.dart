import 'dart:convert';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:meta/meta.dart';

@immutable
class PusherChannelsTriggerEvent
    with PusherChannelsEvent, PusherChannelsSentEventMixin {
  @override
  final String name;

  final String? channelName;

  final dynamic data;

  const PusherChannelsTriggerEvent({
    required this.name,
    required this.data,
    required this.channelName,
  });

  @override
  String getEncoded() => jsonEncode({
        PusherChannelsEvent.eventNameKey: name,
        if (channelName != null) PusherChannelsEvent.channelKey: channelName,
        PusherChannelsEvent.dataKey: data,
      });
}
