import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// An interface designed for the events that are sent to a server.
mixin PusherChannelsSentEventMixin on PusherChannelsEvent {
  /// Encodes this event as String.
  ///
  /// See docs: [Double encoding](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#double-encoding)
  String getEncoded();
}

/// An interface designed to get [data] lazily and efficiently than with [tryGetDataAsMap].
///
/// Usually, used by the predefined Pusher Channels events, such as [PusherChannelsConnectionEstablishedEvent]
mixin PusherChannelsMapDataEventMixin on PusherChannelsReadEventMixin {
  /// A lazily initialized field that is the same as [data] but in a deserialized form.
  @protected
  abstract final Map<String, dynamic> deserializedMapData;
}

/// An interface for readable events.
mixin PusherChannelsReadEventMixin on PusherChannelsEvent {
  /// Appears to be an object that may have following structure:
  /// `{event: String?, channel: String?, data: dynamic, user_id: String?, }`
  ///
  /// See docs:
  /// - [Double encoding](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#double-encoding)
  /// - [Channel Events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#channel-events-pusher-channels-greater-client)
  Map<String, dynamic> get rootObject;

  /// Extracts an event name from the [rootObject] under the [PusherChannelsEvent.eventNameKey] key.
  ///
  /// Gives `''` if it is [Null].
  @override
  String get name =>
      rootObject[PusherChannelsEvent.eventNameKey]?.toString() ?? '';

  /// Extracts event data from the [rootObject] under the [PusherChannelsEvent.dataKey] key.
  dynamic get data => rootObject[PusherChannelsEvent.dataKey];

  /// Tries to deserialize and return the [data] as Map with [safeMessageToMapDeserializer].
  Map<String, dynamic>? tryGetDataAsMap() => safeMessageToMapDeserializer(data);
}

/// A base data interface of events.
@immutable
abstract class PusherChannelsEvent {
  String get name;

  static const eventNameKey = 'event';
  static const dataKey = 'data';
  static const channelKey = 'channel';
  static const userIdKey = 'user_id';
  static const errorTypeKey = 'type';
  static const errorKey = 'error';
}
