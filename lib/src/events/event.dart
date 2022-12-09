import 'package:meta/meta.dart';

mixin ChannelEventMixin<T> on PusherChannelsEvent {
  abstract final String channelName;
}

@immutable
abstract class PusherChannelsEvent {
  abstract final String name;

  static const eventNameKey = 'event';
  static const dataKey = 'data';
}
