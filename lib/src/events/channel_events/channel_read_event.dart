import 'dart:convert';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

/// An implementation of [PusherChannelsReadEvent] that can be
/// received from [Channel.bind].
class ChannelReadEvent extends PusherChannelsReadEvent {
  @protected
  final Channel channel;

  ChannelReadEvent._({
    required Map<String, dynamic> rootObject,
    required this.channel,
  }) : super(rootObject: rootObject);

  @internal
  factory ChannelReadEvent.internalCreate({
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

  @internal
  factory ChannelReadEvent.fromPusherChannelsReadEvent(
    Channel channel,
    PusherChannelsReadEvent readEvent,
  ) =>
      ChannelReadEvent._(
        rootObject: readEvent.rootObject,
        channel: channel,
      );

  @internal
  factory ChannelReadEvent.forSubscriptionError(
    Channel channel, {
    required String type,
    required String errorMessage,
  }) {
    return ChannelReadEvent.internalCreate(
      name: Channel.subscriptionErrorEventName,
      data: {
        PusherChannelsEvent.errorTypeKey: type,
        PusherChannelsEvent.errorKey: errorMessage,
      },
      channel: channel,
    );
  }

  @override
  String get channelName => channel.name;

  ChannelReadEvent copyWithName(String name) {
    return ChannelReadEvent._(
      rootObject: {
        ...rootObject,
        PusherChannelsEvent.eventNameKey: name,
      },
      channel: channel,
    );
  }

  static String _tryEncodeData(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return jsonEncode(<String, String>{});
    }
  }
}
