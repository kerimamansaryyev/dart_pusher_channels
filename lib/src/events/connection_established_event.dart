import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

@immutable
class PusherChannelsConnectionEstablishedEvent implements PusherChannelsEvent {
  static const _activityTimeoutKey = 'activity_timeout';
  static const _socketIdKey = 'socket_id';

  final String socketId;
  @protected
  final int? activityTimeoutInSeconds;

  @override
  final String name = PusherChannelsEventNames.connectionEstablished;

  const PusherChannelsConnectionEstablishedEvent._({
    required this.activityTimeoutInSeconds,
    required this.socketId,
  });

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
        name != PusherChannelsEventNames.connectionEstablished) {
      return null;
    }

    final data = safeMessageToMapDeserializer(
      root[PusherChannelsEvent.dataKey],
    );

    final activityTimeout = int.tryParse(
      data?[_activityTimeoutKey]?.toString() ?? '',
    );
    final socketId = data?[_socketIdKey]?.toString();

    if (socketId == null) {
      return null;
    }

    return PusherChannelsConnectionEstablishedEvent._(
      activityTimeoutInSeconds: activityTimeout,
      socketId: socketId,
    );
  }
}
