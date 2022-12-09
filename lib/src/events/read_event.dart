import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

class PusherChannelsReadEvent
    implements PusherChannelsEvent, PusherChannelsEventWithDataMixin {
  @protected
  final Map<String, dynamic> rootObject;

  const PusherChannelsReadEvent._({
    required this.rootObject,
  });

  @override
  dynamic get data => rootObject[PusherChannelsEvent.dataKey];

  @override
  String get name =>
      rootObject[PusherChannelsEvent.eventNameKey]?.toString() ?? '';

  static PusherChannelsReadEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (name == null || root == null) {
      return null;
    }

    return PusherChannelsReadEvent._(
      rootObject: root,
    );
  }
}
