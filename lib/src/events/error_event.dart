import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// A data class representing the events with name `pusher:error`.
///
/// See docs:
/// - [Connection events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#connection-events)
/// - [System events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#system-events)
@immutable
class PusherChannelsErrorEvent
    with
        PusherChannelsEvent,
        PusherChannelsReadEventMixin,
        PusherChannelsMapDataEventMixin {
  static const eventName = 'pusher:error';
  static const _codeKey = 'code';
  static const _messageKey = 'message';

  @override
  final Map<String, dynamic> rootObject;

  @override
  final Map<String, dynamic> deserializedMapData;

  const PusherChannelsErrorEvent._({
    required this.deserializedMapData,
    required this.rootObject,
  });

  int? get code => int.tryParse(
        deserializedMapData[_codeKey]?.toString() ?? '',
      );
  String? get message => deserializedMapData[_messageKey]?.toString();

  static PusherChannelsErrorEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != PusherChannelsErrorEvent.eventName) {
      return null;
    }

    final data = safeMessageToMapDeserializer(
      root[PusherChannelsEvent.dataKey],
    );

    return PusherChannelsErrorEvent._(
      rootObject: root,
      deserializedMapData: <String, dynamic>{...?data},
    );
  }
}
