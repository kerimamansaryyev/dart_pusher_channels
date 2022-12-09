import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

@internal
@immutable
class PusherChannelsPongEvent
    implements
        PusherChannelsEvent,
        PusherChannelsSentEventMixin,
        PusherChannelsPredefinedEventMixin {
  static const _name = PusherChannelsEventNames.pong;

  @override
  final String name = _name;

  const PusherChannelsPongEvent._();

  static PusherChannelsPongEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != _name) {
      return null;
    }

    return const PusherChannelsPongEvent._();
  }

  @override
  String getEncoded() => jsonEncode({
        PusherChannelsEvent.eventNameKey: name,
        PusherChannelsEvent.dataKey: const <String, String>{},
      });
}
