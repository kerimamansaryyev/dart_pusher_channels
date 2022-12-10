import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

@immutable
class PusherChannelsConnectionEstablishedEvent
    with
        PusherChannelsEvent,
        PusherChannelsReadEventMixin,
        PusherChannelsMapDataEventMixin,
        PusherChannelsPredefinedEventMixin {
  static const _activityTimeoutKey = 'activity_timeout';
  static const _socketIdKey = 'socket_id';
  static const _name = PusherChannelsEventNames.connectionEstablished;

  @override
  final Map<String, dynamic> rootObject;

  @override
  final Map<String, dynamic> deserializedMapData;

  const PusherChannelsConnectionEstablishedEvent._({
    required this.rootObject,
    required this.deserializedMapData,
  });

  String get socketId => deserializedMapData[_socketIdKey] as String;
  @protected
  int? get activityTimeoutInSeconds => int.tryParse(
        deserializedMapData[_activityTimeoutKey]?.toString() ?? '',
      );

  Duration? get activityTimeoutDuration {
    final seconds = activityTimeoutInSeconds;
    if (seconds == null) {
      return null;
    }
    return Duration(
      seconds: seconds,
    );
  }

  static PusherChannelsConnectionEstablishedEvent? tryParseFromDynamic(
    dynamic message,
  ) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != _name) {
      return null;
    }

    final data = safeMessageToMapDeserializer(
      root[PusherChannelsEvent.dataKey],
    );
    final socketId = data?[_socketIdKey]?.toString();

    if (socketId == null) {
      return null;
    }

    return PusherChannelsConnectionEstablishedEvent._(
      rootObject: root,
      deserializedMapData: <String, dynamic>{...?data},
    );
  }
}