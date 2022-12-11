import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';

class ChannelReadEvent extends PusherChannelsReadEvent {
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

  @override
  String get channelName => channel.name;

  String? get userId => rootObject[PusherChannelsEvent.userIdKey]?.toString();
}
