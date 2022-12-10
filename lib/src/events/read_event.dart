import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';

class PusherChannelsReadEvent
    with PusherChannelsEvent, PusherChannelsReadEventMixin {
  @override
  final Map<String, dynamic> rootObject;

  PusherChannelsReadEvent._({
    required this.rootObject,
  });

  static PusherChannelsReadEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    if (root == null) {
      return null;
    }

    return PusherChannelsReadEvent._(
      rootObject: root,
    );
  }
}
