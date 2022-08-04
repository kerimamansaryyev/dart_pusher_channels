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
  @protected
  final ConnectionDelegate connectionDelegate;

  /// Channel name
  final String name;

  Channel({required this.name, required this.connectionDelegate});

  /// Subscribing to the channel sending [PusherEventNames.subscribe] through [ConnectionDelegate]
  void subscribe();

  /// Unsubscribing to the channel sending [PusherEventNames.subscribe] through [ConnectionDelegate]
  void unsubscribe();

  ///Listening for incoming events by given [eventName] over the [ConnectionDelegate.onEvent]
  Stream<ChannelReadEvent> bind(String eventName) => connectionDelegate.onEvent
      .where((event) => event.channelName == name && eventName == event.name)
      .map<ChannelReadEvent>(
        (event) =>
            ChannelReadEvent(name: event.name, data: event.data, channel: this),
      );
}

/// Implementation of pusher private channels using [AuthorizationDelegate] to get auth code for subscribing through authentication
/// middleware.
class PrivateChannel extends Channel {
  /// Define AuthorizationDelegate to get auth string and subscribe to a channel
  final AuthorizationDelegate authorizationDelegate;

  /// Called when [authorizationDelegate] fails to get auth string
  final void Function(PusherAuthenticationException error)? onAuthFailed;

  PrivateChannel({
    required String name,
    required ConnectionDelegate connectionDelegate,
    required this.authorizationDelegate,
    this.onAuthFailed,
  }) : super(name: name, connectionDelegate: connectionDelegate);

  /// [PrivateChannel] subscription is established only if
  /// [ConnectionDelegate.socketId] is set (if connection is established) and
  /// [AuthorizationDelegate.authenticationString] succeeds
  /// with valid auth code.
  @override
  void subscribe() async {
    if (connectionDelegate.socketId == null) {
      return;
    }

    try {
      final code = await authorizationDelegate.authenticationString(
        connectionDelegate.socketId!,
        name,
      );
      connectionDelegate.send(
        SendEvent(
          data: {'channel': name, 'auth': code},
          name: PusherEventNames.subscribe,
          channelName: null,
        ),
      );
    } on PusherAuthenticationException catch (ex) {
      onAuthFailed?.call(ex);
    } catch (_) {}
  }

  /// Unsubscribes this [PrivateChannel] only if
  /// [ConnectionDelegate.socketId] is set (if connection is established)
  @override
  void unsubscribe() {
    if (connectionDelegate.socketId == null) {
      return;
    }

    connectionDelegate.send(
      SendEvent(
        data: {'channel': name},
        name: PusherEventNames.unsubscribe,
        channelName: null,
      ),
    );
  }
}

/// Implementation of pusher public channels
class PublicChannel extends Channel {
  PublicChannel({
    required String name,
    required ConnectionDelegate connectionDelegate,
  }) : super(name: name, connectionDelegate: connectionDelegate);

  /// [PublicChannel] subscription is established only if
  /// [ConnectionDelegate.socketId] is set (if connection is established)
  @override
  void subscribe() {
    if (connectionDelegate.socketId == null) {
      return;
    }

    connectionDelegate.send(
      SendEvent(
        data: {'channel': name},
        name: PusherEventNames.subscribe,
        channelName: null,
      ),
    );
  }

  /// Unsubscribes this [PublicChannel] only if
  /// [ConnectionDelegate.socketId] is set (if connection is established)
  @override
  void unsubscribe() {
    if (connectionDelegate.socketId == null) {
      return;
    }

    connectionDelegate.send(
      SendEvent(
        data: {'channel': name},
        name: PusherEventNames.unsubscribe,
        channelName: null,
      ),
    );
  }
}
