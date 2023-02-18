import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/http_token_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_encrypted_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:dart_pusher_channels/src/utils/constants.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class PusherChannelsClientDisposedException implements PusherChannelsException {
  @override
  String get message =>
      'The instance of PusherChannelsClient is disposed and can\'t be reused. Please, try to create a new instance.';

  const PusherChannelsClientDisposedException();
}

/// A centralized manager of connection and channel bindings.
///
/// `Note`: If an instance of this class has been disposed -
/// it can't be reused. So if you want to use the instance after disposal -
/// you will have to create a new instance.
///
/// - Use [PusherChannelsClient.websocket] to create a client with [PusherChannelsWebSocketConnection].
/// - Use [PusherChannelsClient.custom] to create a client with your own
/// implementation of [PusherChannelsConnection].
///
/// Enables:
/// - Creating channels: [publicChannel], [privateChannel], [presenceChannel].
/// - Listening for all events through [eventStream].
/// - Listening for `pusher:error` events through [pusherErrorEventStream].
/// - Listening for the lifecycle state changes through [lifecycleStream].
/// - Listening for connection/reconnection establishment [onConnectionEstablished].
class PusherChannelsClient {
  bool _isDisposed = false;
  @protected
  final PusherChannelsClientLifeCycleController controller;
  @protected
  final ChannelsManager channelsManager;

  PusherChannelsClient._({
    required this.controller,
    required this.channelsManager,
  });

  factory PusherChannelsClient._baseWithConnection({
    required Duration? activityDurationOverride,
    required Duration defaultActivityDuration,
    required Duration waitForPongDuration,
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    required Duration minimumReconnectDelayDuration,
  }) {
    late final PusherChannelsClient client;

    final controller = PusherChannelsClientLifeCycleController(
      minimumReconnectDuration: minimumReconnectDelayDuration,
      externalEventHandler: (event) => client._handleEvent(event),
      activityDurationOverride: activityDurationOverride,
      waitForPongDuration: waitForPongDuration,
      defaultActivityDuration: defaultActivityDuration,
      connectionDelegate: connectionDelegate,
      connectionErrorHandler: connectionErrorHandler,
    );

    final channelsManager = ChannelsManager(
      channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
        triggerEventDelegate: (event) => client.trigger(event),
        socketIdGetter: () => client.controller.socketId,
        sendEventDelegate: (event) => client.sendEvent(event),
      ),
    );

    return client = PusherChannelsClient._(
      controller: controller,
      channelsManager: channelsManager,
    );
  }

  /// Providing a client with a delegate returning custom implementation of [PusherChannelsConnection].
  /// Parameters:
  /// - [connectionDelegate] : A delegate function that is used by [controller] to create instances [PusherChannelsConnection]
  /// with each connection try.
  /// `Note`: `DON'T` provide a factory that returns a singleton or a same variable beacause [controller] closes it's connection
  /// after each lifecycle.
  /// See the implementation of [PusherChannelsWebSocketConnection] and [PusherChannelsClient.websocket] constructor.
  /// - [connectionErrorHandler] : This handler will be called by [controller] when a connection error is thrown.
  /// - [minimumReconnectDelayDuration] : A minimum delay between connection tries used by [controller] when reconnecting.
  /// - [defaultActivityDuration] : A default timeout duration of activity that is used by [controller] to check
  /// if connection is alive. The value will be used if neither the server activity timeout nor [activityDurationOverride] are provided.
  /// - [activityDurationOverride] : Overrides both the server activity timeout and [defaultActivityDuration].
  /// - [waitForPongDuration] : A timeout duration that is used to wait for the `pong` event right after [controller] sends the `ping` message.
  factory PusherChannelsClient.custom({
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    Duration minimumReconnectDelayDuration = const Duration(seconds: 1),
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        minimumReconnectDelayDuration: minimumReconnectDelayDuration,
        waitForPongDuration: waitForPongDuration,
        activityDurationOverride: activityDurationOverride,
        defaultActivityDuration: defaultActivityDuration,
        connectionDelegate: connectionDelegate,
        connectionErrorHandler: connectionErrorHandler,
      );

  /// Providing a client with a delegate returning [PusherChannelsWebSocketConnection].
  /// Parameters:
  /// - [options] : Options to connect to a server. See [PusherChannelsOptions] for more details.
  /// - [connectionErrorHandler] : This handler will be called by [controller] when a connection error is thrown.
  /// - [minimumReconnectDelayDuration] : A minimum delay between connection tries used by [controller] when reconnecting.
  /// - [defaultActivityDuration] : A default timeout duration of activity that is used by [controller] to check
  /// if connection is alive. The value will be used if neither the server activity timeout nor [activityDurationOverride] are provided.
  /// - [activityDurationOverride] : Overrides both the server activity timeout and [defaultActivityDuration].
  /// - [waitForPongDuration] : A timeout duration that is used to wait for the `pong` event right after [controller] sends the `ping` message.
  factory PusherChannelsClient.websocket({
    required PusherChannelsOptions options,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    Duration minimumReconnectDelayDuration = const Duration(seconds: 1),
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        minimumReconnectDelayDuration: minimumReconnectDelayDuration,
        waitForPongDuration: waitForPongDuration,
        activityDurationOverride: activityDurationOverride,
        defaultActivityDuration: defaultActivityDuration,
        connectionDelegate: () => PusherChannelsWebSocketConnection(
          uri: options.uri,
        ),
        connectionErrorHandler: connectionErrorHandler,
      );

  @visibleForTesting
  Future<void> getConnectionCompleterFuture() =>
      controller.getCompleterFuture();

  /// Creates a private encrypted channel.
  ///
  /// Usage is the same as with the private channels but note that your
  /// server side has to support the encrypted channels feature.
  ///
  /// Example:
  /// ```dart
  ///   PrivateEncryptedChannel myEncryptedChannel = client.privateEncryptedChannel(
  ///   'private-encrypted-channel',
  ///   authorizationDelegate:
  ///       EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateEncryptedChannel(
  ///     authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
  ///     headers: const {},
  ///   ),
  /// );
  /// ```
  ///
  /// Provide your implementation of [EndpointAuthorizableChannelAuthorizationDelegate] or you
  /// may use: [EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateEncryptedChannel]
  ///
  /// You may provide your own delegate function to encode the decrypted message into the plain text
  /// by providing [eventDataEncodeDelegate]. Otherwise the default one will be used.
  /// Example:
  /// ```dart
  /// ...
  /// eventDataEncodeDelegate: (Uint8List bytes) => utf8.decode(bytes),
  /// ...
  /// ```
  ///
  /// `Note`: if [forceCreateNewInstance] is `true` then this client will return a new instance each time
  /// this method is called instead of giving an internally linked one.
  ///
  /// Example:
  /// ```dart
  /// var oldVariable = client.publicChannel('hello');
  /// var newVariable = client.publicChannel('hello');
  /// // prints true
  /// print(oldVariable == newVariable);

  /// var newestVariable = client.publicChannel(
  ///   'hello',
  ///   forceCreateNewInstance: true,
  // );

  /// // prints false
  /// print(newestVariable == oldVariable || newestVariable == newVariable);
  /// ```
  PrivateEncryptedChannel privateEncryptedChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateEncryptedChannelAuthorizationData>
        authorizationDelegate,
    bool forceCreateNewInstance = false,
    PrivateEncryptedChannelEventDataEncodeDelegate eventDataEncodeDelegate =
        PrivateEncryptedChannel.defaultEventDataEncoder,
  }) =>
      channelsManager.privateEncryptedChannel(
        channelName,
        authorizationDelegate: authorizationDelegate,
        forceCreateNewInstance: forceCreateNewInstance,
        eventDataEncodeDelegate: eventDataEncodeDelegate,
      );

  /// Creates a public channel.
  ///
  /// `Note`: if [forceCreateNewInstance] is `true` then this client will return a new instance each time
  /// this method is called instead of giving an internally linked one.
  ///
  /// Example:
  /// ```dart
  /// var oldVariable = client.publicChannel('hello');
  /// var newVariable = client.publicChannel('hello');
  /// // prints true
  /// print(oldVariable == newVariable);

  /// var newestVariable = client.publicChannel(
  ///   'hello',
  ///   forceCreateNewInstance: true,
  // );

  /// // prints false
  /// print(newestVariable == oldVariable || newestVariable == newVariable);
  /// ```
  PublicChannel publicChannel(
    String channelName, {
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.publicChannel(
      channelName,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

  /// Creates a private channel.
  ///
  /// Provide your implementation of [EndpointAuthorizableChannelAuthorizationDelegate] or you
  /// may use: [EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel]
  ///
  /// Example:
  /// ```dart
  /// PrivateChannel myPrivateChannel = client.privateChannel(
  ///   'private-channel',
  ///   authorizationDelegate:
  ///       EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
  ///     authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
  ///     headers: const {},
  ///   ),
  /// );
  /// ```
  ///
  /// `Note`: if [forceCreateNewInstance] is `true` then this client will return a new instance each time
  /// this method is called instead of giving an internally linked one.
  ///
  /// Example:
  /// ```dart
  /// var oldVariable = client.publicChannel('hello');
  /// var newVariable = client.publicChannel('hello');
  /// // prints true
  /// print(oldVariable == newVariable);

  /// var newestVariable = client.publicChannel(
  ///   'hello',
  ///   forceCreateNewInstance: true,
  // );

  /// // prints false
  /// print(newestVariable == oldVariable || newestVariable == newVariable);
  /// ```
  PrivateChannel privateChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData>
        authorizationDelegate,
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.privateChannel(
      channelName,
      authorizationDelegate: authorizationDelegate,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

  /// Creates a private channel.
  ///
  /// Provide your implementation of [EndpointAuthorizableChannelAuthorizationDelegate] or you
  /// may use: [EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel]
  ///
  /// Example:
  /// ```dart
  /// PresenceChannel myPresenceChannel = client.presenceChannel(
  ///   'presence-channel',
  ///   authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate
  ///       .forPresenceChannel(
  ///     authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
  ///     headers: const {},
  ///   ),
  ///  );
  /// ```
  /// `Note`: if [forceCreateNewInstance] is `true` then this client will return a new instance each time
  /// this method is called instead of giving an internally linked one.
  ///
  /// Example:
  /// ```dart
  /// var oldVariable = client.publicChannel('hello');
  /// var newVariable = client.publicChannel('hello');
  /// // prints true
  /// print(oldVariable == newVariable);

  /// var newestVariable = client.publicChannel(
  ///   'hello',
  ///   forceCreateNewInstance: true,
  // );

  /// // prints false
  /// print(newestVariable == oldVariable || newestVariable == newVariable);
  /// ```
  PresenceChannel presenceChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PresenceChannelAuthorizationData>
        authorizationDelegate,
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.presenceChannel(
      channelName,
      authorizationDelegate: authorizationDelegate,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

  /// Used to listen for all the events received from a server.
  Stream<PusherChannelsReadEvent> get eventStream => controller.eventStream
      .whereType<PusherChannelsReadEventMixin>()
      .map(PusherChannelsReadEvent.fromReadable);

  /// Used to listen for events with name `pusher:error`.
  Stream<PusherChannelsReadEvent> get pusherErrorEventStream => eventStream
      .whereType<PusherChannelsErrorEvent>()
      .map(PusherChannelsReadEvent.fromReadable);

  /// Used to listen for the lifecycle changes of the [controller].
  /// For exmaple, when this client connects, reconnects, disconnects, pending connection an e.t.c.
  /// See [PusherChannelsClientLifeCycleState] for more details.
  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      controller.lifecycleStream;

  /// Used to listen on whenever the client manages to establish connection
  /// receiving the event with name `pusher:connection_established`
  Stream<void> get onConnectionEstablished => lifecycleStream
      .where(
        (event) =>
            event == PusherChannelsClientLifeCycleState.establishedConnection,
      )
      .map(voidStreamMapper);

  bool get isDisposed => _isDisposed;

  /// Connects to a server via [controller].
  Future<void> connect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return controller.connectSafely();
  }

  /// Disconnects from a server via [controller].
  Future<void> disconnect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return controller.disconnectSafely();
  }

  /// Reconnects to a server via [controller].
  Future<void> reconnect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return controller.reconnectSafely();
  }

  /// Triggers the [event] to a server.
  @internal
  void trigger(PusherChannelsTriggerEvent event) {
    if (_isDisposed) {
      return;
    }
    controller.triggerEvent(
      event,
    );
  }

  /// Sends the [event] to a server.
  @internal
  void sendEvent(PusherChannelsSentEventMixin event) {
    if (_isDisposed) {
      return;
    }
    controller.sendEvent(event);
  }

  /// Destroys [controller] and [channelsManager] making this instance
  /// unusable.
  void dispose() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    _isDisposed = true;
    controller.dispose();
    channelsManager.dispose();
  }

  /// Allows handling events for the [channelsManager] from the [controller].
  void _handleEvent(PusherChannelsEvent event) {
    if (_isDisposed) {
      return;
    }
    channelsManager.handleEvent(event);
  }
}
