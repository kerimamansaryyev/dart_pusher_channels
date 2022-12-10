import 'package:meta/meta.dart';

mixin PusherChannelsPredefinedEventMixin on PusherChannelsEvent {}

mixin PusherChannelsSentEventMixin on PusherChannelsEvent {
  String getEncoded();
}

@internal
mixin PusherChannelsEventWithDataMixin on PusherChannelsEvent {
  abstract final dynamic data;
}

@immutable
abstract class PusherChannelsEvent {
  abstract final String name;

  static const eventNameKey = 'event';
  static const dataKey = 'data';
  static const channelKey = 'channel';
}
