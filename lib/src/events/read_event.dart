import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';

/// A data class represents readable Pusher Channels events.
///
/// Usually, they are received from [PusherChannelsClient.eventStream].
///
/// See also:
/// - [PusherChannelsEvent]
/// - [PusherChannelsReadEventMixin]
///
class PusherChannelsReadEvent
    with PusherChannelsEvent, PusherChannelsReadEventMixin {
  @override
  final Map<String, dynamic> rootObject;

  PusherChannelsReadEvent({
    required this.rootObject,
  });

  /// An adapter to create an instance from other readables.
  factory PusherChannelsReadEvent.fromReadable(
    PusherChannelsReadEventMixin event,
  ) =>
      PusherChannelsReadEvent(
        rootObject: {...event.rootObject},
      );

  String? get channelName =>
      rootObject[PusherChannelsEvent.channelKey]?.toString();

  String? get userId => rootObject[PusherChannelsEvent.userIdKey]?.toString();

  static PusherChannelsReadEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    if (root == null) {
      return null;
    }

    return PusherChannelsReadEvent(
      rootObject: root,
    );
  }
}
