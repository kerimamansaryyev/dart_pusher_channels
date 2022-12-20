import 'dart:convert';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// The event class that implements the `ping` events.
///
/// Can be either sent or received. That's why implements both: [PusherChannelsSentEventMixin], [PusherChannelsReadEventMixin].
@immutable
class PusherChannelsPingEvent
    with
        PusherChannelsEvent,
        PusherChannelsSentEventMixin,
        PusherChannelsReadEventMixin {
  static const eventName = 'pusher:ping';

  @override
  final String name = eventName;

  const PusherChannelsPingEvent();

  static PusherChannelsPingEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != PusherChannelsPingEvent.eventName) {
      return null;
    }

    return const PusherChannelsPingEvent();
  }

  @override
  String getEncoded() => jsonEncode({
        PusherChannelsEvent.eventNameKey: name,
        PusherChannelsEvent.dataKey: const <String, String>{},
      });

  @override
  Map<String, dynamic> get rootObject => {
        PusherChannelsEvent.eventNameKey: name,
        PusherChannelsEvent.dataKey: jsonEncode(<String, String>{}),
      };
}
