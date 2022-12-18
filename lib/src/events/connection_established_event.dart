import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// A data class representing the events with name `pusher:connection_established`.
///
/// See docs:
/// - [Connection events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#connection-events)
/// - [System events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#system-events)
@immutable
class PusherChannelsConnectionEstablishedEvent
    with
        PusherChannelsEvent,
        PusherChannelsReadEventMixin,
        PusherChannelsMapDataEventMixin {
  static const eventName = 'pusher:connection_established';
  static const _activityTimeoutKey = 'activity_timeout';
  static const _socketIdKey = 'socket_id';

  @override
  final Map<String, dynamic> rootObject;

  @override
  final Map<String, dynamic> deserializedMapData;

  const PusherChannelsConnectionEstablishedEvent._({
    required this.rootObject,
    required this.deserializedMapData,
  });

  String get socketId => deserializedMapData[_socketIdKey].toString();
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
    if (root == null ||
        name != PusherChannelsConnectionEstablishedEvent.eventName) {
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
