import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

mixin PusherChannelsSentEventMixin on PusherChannelsEvent {
  String getEncoded();
}

mixin PusherChannelsMapDataEventMixin on PusherChannelsReadEventMixin {
  abstract final Map<String, dynamic> deserializedMapData;
}

mixin PusherChannelsReadEventMixin on PusherChannelsEvent {
  abstract final Map<String, dynamic> rootObject;

  @override
  String get name =>
      rootObject[PusherChannelsEvent.eventNameKey]?.toString() ?? '';

  dynamic get data => rootObject[PusherChannelsEvent.dataKey];

  Map<String, dynamic>? tryGetDataAsMap() => safeMessageToMapDeserializer(data);
}

@immutable
abstract class PusherChannelsEvent {
  String get name;

  static const eventNameKey = 'event';
  static const dataKey = 'data';
  static const channelKey = 'channel';
  static const userIdKey = 'user_id';
  static const errorTypeKey = 'type';
  static const errorKey = 'error';
}
