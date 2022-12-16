import 'dart:convert';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

class ChannelReadEvent extends PusherChannelsReadEvent {
  @protected
  final Channel channel;

  ChannelReadEvent._({
    required Map<String, dynamic> rootObject,
    required this.channel,
  }) : super(rootObject: rootObject);

  factory ChannelReadEvent.internal({
    required String name,
    required Channel channel,
    required Map<String, dynamic> data,
  }) =>
      ChannelReadEvent._(
        rootObject: {
          PusherChannelsEvent.eventNameKey: name,
          PusherChannelsEvent.channelKey: channel.name,
          PusherChannelsEvent.dataKey: _tryEncodeData(data),
        },
        channel: channel,
      );

  factory ChannelReadEvent.fromPusherChannelsReadEvent(
    Channel channel,
    PusherChannelsReadEvent readEvent,
  ) =>
      ChannelReadEvent._(
        rootObject: readEvent.rootObject,
        channel: channel,
      );

  factory ChannelReadEvent.forSubscriptionError(
    Channel channel, {
    required String type,
    required String errorMessage,
  }) {
    return ChannelReadEvent.internal(
      name: Channel.subscriptionErrorEventName,
      data: {
        PusherChannelsEvent.errorTypeKey: type,
        PusherChannelsEvent.errorKey: errorMessage,
      },
      channel: channel,
    );
  }

  ChannelReadEvent copyWithName(String name) {
    return ChannelReadEvent._(
      rootObject: {
        ...rootObject,
        PusherChannelsEvent.eventNameKey: name,
      },
      channel: channel,
    );
  }

  @override
  String get channelName => channel.name;

  static String _tryEncodeData(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return jsonEncode(<String, String>{});
    }
  }
}
