import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

@immutable
class PusherChannelsErrorEvent
    with
        PusherChannelsEvent,
        PusherChannelsReadEventMixin,
        PusherChannelsMapDataEventMixin,
        PusherChannelsPredefinedEventMixin {
  static const _codeKey = 'code';
  static const _messageKey = 'message';
  static const _name = PusherChannelsEventNames.error;

  int? get code => int.tryParse(
        deserializedMapData[_codeKey]?.toString() ?? '',
      );
  String? get message => deserializedMapData[_messageKey]?.toString();

  @override
  final Map<String, dynamic> rootObject;

  @override
  final Map<String, dynamic> deserializedMapData;

  const PusherChannelsErrorEvent._({
    required this.deserializedMapData,
    required this.rootObject,
  });

  static PusherChannelsErrorEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != _name) {
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
