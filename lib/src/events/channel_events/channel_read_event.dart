import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

class ChannelReadEvent extends PusherChannelsReadEvent {
  @protected
  final Channel channel;

  ChannelReadEvent({
    required Map<String, dynamic> rootObject,
    required this.channel,
  }) : super(rootObject: rootObject);

  factory ChannelReadEvent.fromPusherChannelsReadEvent(
    Channel channel,
    PusherChannelsReadEvent readEvent,
  ) =>
      ChannelReadEvent(
        rootObject: readEvent.rootObject,
        channel: channel,
      );

  factory ChannelReadEvent.forSubscriptionError(
    Channel channel, {
    required String type,
    required String errorMessage,
  }) {
    return ChannelReadEvent(
      rootObject: {
        PusherChannelsEvent.eventNameKey: Channel.subscriptionErrorEventName,
        PusherChannelsEvent.channelKey: channel.name,
        PusherChannelsEvent.dataKey: {
          'type': type,
          'error': errorMessage,
        }
      },
      channel: channel,
    );
  }

  ChannelReadEvent copyWithName(String name) {
    return ChannelReadEvent(
      rootObject: {
        ...rootObject,
        PusherChannelsEvent.eventNameKey: name,
      },
      channel: channel,
    );
  }

  @override
  String get channelName => channel.name;
}
