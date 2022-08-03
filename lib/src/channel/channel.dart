///The channels library includes classes and interfaces for subscribing, unsubscribing, listening events from channels
///Fot the present time - there are only 2 types of channels - Private, Public

library channels;

import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/src/exceptions/exception.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../connection.dart';
import '../event.dart';
import '../event_names.dart';

part 'authorization_delegate.dart';
part 'event.dart';

///An interface to represent the channels based on  the [Pusher documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events)
abstract class Channel {
  /// Channel name
  final String name;

  /// Subscribing to the channel sending [PusherEventNames.subscribe] through [ConnectionDelegate]
  void subscribe();

  /// Unsubscribing to the channel sending [PusherEventNames.subscribe] through [ConnectionDelegate]
  void unsubscribe();

  @protected
  final ConnectionDelegate connectionDelegate;

  ///Listening for incoming events by given [eventName] over the [connectionDelegate.onEvent]
  Stream<ChannelReadEvent> bind(String eventName) => connectionDelegate.onEvent
      .where((event) => event.channelName == name && eventName == event.name)
      .map<ChannelReadEvent>((event) =>
          ChannelReadEvent(name: event.name, data: event.data, channel: this));

  Channel({required this.name, required this.connectionDelegate});
}

/// Implementation of pusher private channels using [AuthorizationDelegate] to get auth code for subscribing through authenticaton
/// middleware.
class PrivateChannel extends Channel {
  PrivateChannel(
      {required String name,
      required ConnectionDelegate connectionDelegate,
      this.onAuthFailed,
      required this.authorizationDelegate})
      : super(name: name, connectionDelegate: connectionDelegate);

  /// Define AuthorizationDelegate to get auth string and subscribe to a channel
  final AuthorizationDelegate authorizationDelegate;

  /// Called when [authorizationDelegate] fails to get auth string
  final void Function(PusherAuthenticationException error)? onAuthFailed;

  /// [PrivateChannel] subscription is established only if
  /// [ConnectionDelegate.socketId] is set and
  /// [authorizationDelegate.authenticationString] succeeds
  /// with valid auth code.
  @override
  void subscribe() async {
    if (connectionDelegate.socketId == null) {
      return;
    }

    try {
      var code = await authorizationDelegate.authenticationString(
        connectionDelegate.socketId!,
        name,
      );
      connectionDelegate.send(SendEvent(
        data: {'channel': name, 'auth': code},
        name: PusherEventNames.subscribe,
        channelName: null,
      ));
    } on PusherAuthenticationException catch (ex) {
      onAuthFailed?.call(ex);
      // ignore: empty_catches
    } catch (ex) {}
  }

  @override
  void unsubscribe() {
    connectionDelegate.send(SendEvent(
        data: {'channel': name},
        name: PusherEventNames.unsubscribe,
        channelName: null));
  }
}

/// Implementation of pusher public channels
class PublicChannel extends Channel {
  PublicChannel(
      {required String name, required ConnectionDelegate connectionDelegate})
      : super(name: name, connectionDelegate: connectionDelegate);

  @override
  void subscribe() {
    connectionDelegate.send(SendEvent(
        data: {'channel': name},
        name: PusherEventNames.subscribe,
        channelName: null));
  }

  @override
  void unsubscribe() {
    connectionDelegate.send(SendEvent(
        data: {'channel': name},
        name: PusherEventNames.unsubscribe,
        channelName: null));
  }
}
