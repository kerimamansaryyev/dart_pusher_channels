import 'dart:convert';

import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

@immutable
class PusherChannelsPingEvent
    with
        PusherChannelsEvent,
        PusherChannelsSentEventMixin,
        PusherChannelsPredefinedEventMixin {
  static const _name = PusherChannelsEventNames.ping;

  @override
  final String name = _name;

  const PusherChannelsPingEvent();

  static PusherChannelsPingEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != _name) {
      return null;
    }

    return const PusherChannelsPingEvent();
  }

  @override
  String getEncoded() => jsonEncode({
        PusherChannelsEvent.eventNameKey: name,
        PusherChannelsEvent.dataKey: const <String, String>{},
      });
}
