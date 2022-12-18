import 'dart:convert';

import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';

/// A data class that represents events with name
/// `pusher:subscribe`.
///
/// Instances of this class are used to be sent to a server
/// to subscribe to a channel with name [channelName].
///
/// Some of the channels require users to be authorized.
/// When subscribing to these kind of channels, following properties are provided as well: [authKey], [channelDataEncoded],
///
/// See also:
/// - [EndpointAuthorizableChannel]
/// - [PrivateChannel]
/// - [PresenceChannel].
///
/// See docs: [Subscription events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events)
///
class ChannelSubscribeEvent
    with PusherChannelsEvent, PusherChannelsSentEventMixin {
  static const eventName = 'pusher:subscribe';

  @override
  final String name = eventName;

  final String channelName;

  final String? channelDataEncoded;

  final String? authKey;

  const ChannelSubscribeEvent({
    required this.channelName,
    required this.authKey,
    required this.channelDataEncoded,
  });

  const ChannelSubscribeEvent.forPublicChannel({
    required String channelName,
  }) : this(
          channelName: channelName,
          authKey: null,
          channelDataEncoded: null,
        );

  const ChannelSubscribeEvent.forPrivateChannel({
    required String channelName,
    required String authKey,
  }) : this(
          channelName: channelName,
          authKey: authKey,
          channelDataEncoded: null,
        );

  const ChannelSubscribeEvent.forPresenceChannel({
    required String channelName,
    required String authKey,
    required String channelDataEncoded,
  }) : this(
          channelName: channelName,
          authKey: authKey,
          channelDataEncoded: channelDataEncoded,
        );

  @override
  String getEncoded() {
    final authorizationKey = authKey;
    final channelData = channelDataEncoded;

    return jsonEncode({
      PusherChannelsEvent.eventNameKey: name,
      PusherChannelsEvent.dataKey: <String, String>{
        PusherChannelsEvent.channelKey: channelName,
        if (authorizationKey != null) 'auth': authorizationKey,
        if (channelData != null) 'channel_data': channelData,
      }
    });
  }
}
