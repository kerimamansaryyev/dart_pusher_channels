import 'dart:convert';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// The event class that implements the `pong` events.
///
/// Can be either sent or received. That's why implements both: [PusherChannelsSentEventMixin], [PusherChannelsReadEventMixin].
@immutable
class PusherChannelsPongEvent
    with
        PusherChannelsEvent,
        PusherChannelsSentEventMixin,
        PusherChannelsReadEventMixin {
  static const eventName = 'pusher:pong';

  @override
  final String name = eventName;

  const PusherChannelsPongEvent();

  static PusherChannelsPongEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != PusherChannelsPongEvent.eventName) {
      return null;
    }

    return const PusherChannelsPongEvent();
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
