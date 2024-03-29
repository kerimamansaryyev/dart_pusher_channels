import 'dart:convert';
import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/x25519.dart';

/// A delegate function used for encoding the decrypted message received from the server.
typedef PrivateEncryptedChannelEventDataEncodeDelegate = String Function(
  Uint8List bytes,
);

class _PusherChannelsDecryptionException implements PusherChannelsException {
  @override
  final String message;

  const _PusherChannelsDecryptionException.nonceOrCiphertextNull()
      : message = 'Received nonce or ciphertext is null';

  const _PusherChannelsDecryptionException.decryptionFailed()
      : message = 'Failed to decrypt the event';
}

extension _ChannelReadEventExtension on PusherChannelsReadEvent {
  PusherChannelsReadEvent copyWithDecryptedData({
    required Uint8List key,
    required PrivateEncryptedChannelEventDataEncodeDelegate encodeDelegate,
  }) {
    final data = tryGetDataAsMap() ?? <String, dynamic>{};

    if (data.isEmpty) {
      return this;
    }

    final nonceString = data['nonce'];
    final ciphertextString = data['ciphertext'];

    if (nonceString is! String || ciphertextString is! String) {
      throw const _PusherChannelsDecryptionException.nonceOrCiphertextNull();
    }

    try {
      final nonce = base64Decode(nonceString);
      final ciphertext = base64Decode(ciphertextString);
      final secretBox = SecretBox(key);
      final decrypted = secretBox.decrypt(
        ByteList(ciphertext),
        nonce: nonce,
      );
      final plaintext = encodeDelegate(decrypted);

      return PusherChannelsReadEvent(
        rootObject: {
          ...rootObject,
          PusherChannelsEvent.dataKey: plaintext,
        },
      );
    } catch (exception) {
      throw const _PusherChannelsDecryptionException.decryptionFailed();
    }
  }
}

/// The encrypted channels behave as the private channels
/// when it comes to the authorization process. So they use [authKey]
/// to subscribe, [sharedSecret] is used to decrypt the data of each incoming.
///
/// See also:
/// - [EndpointAuthorizableChannelAuthorizationDelegate]
/// - [EndpointAuthorizationData]
/// - [EndpointAuthorizableChannel]
/// - [Encrypted channels docs](https://pusher.com/docs/channels/using_channels/encrypted-channels/)
@immutable
class PrivateEncryptedChannelAuthorizationData
    implements EndpointAuthorizationData {
  final String authKey;
  final Uint8List sharedSecret;

  const PrivateEncryptedChannelAuthorizationData({
    required this.authKey,
    required this.sharedSecret,
  });
}

/// A data class representing a state
/// of [PrivateEncryptedChannel]'s instances.
@immutable
class PrivateEncryptedChannelState implements ChannelState {
  @override
  final ChannelStatus status;
  @override
  final int? subscriptionCount;

  const PrivateEncryptedChannelState._({
    required this.status,
    required this.subscriptionCount,
  });

  const PrivateEncryptedChannelState.initial()
      : this._(
          status: ChannelStatus.idle,
          subscriptionCount: null,
        );

  PrivateEncryptedChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
  }) =>
      PrivateEncryptedChannelState._(
        status: status ?? this.status,
        subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      );
}

/// **IMPORTANT!** Your server library has to support the encrypted channels
/// feature in order to use this kind of channel.
///
/// Encrypted channels do not support triggering the client events by the protocol.
///
/// End-to-end encrypted channels provide the same subscription restrictions as private channels.
/// In addition, the data field of events published to end-to-end encrypted channels is encrypted using an implementation of the Secretbox encryption standard defined in NaCl before it leaves your server.
/// Only authorized subscribers have access to the channel specific decryption key.
///
/// See also:
/// - [EndpointAuthorizableChannel]
/// - [EndpointAuthorizableChannelAuthorizationDelegate]
/// - [PrivateEncryptedChannelAuthorizationData]
///
class PrivateEncryptedChannel extends EndpointAuthorizableChannel<
    PrivateEncryptedChannelState, PrivateEncryptedChannelAuthorizationData> {
  /// Used to encode the decrypted message.
  final PrivateEncryptedChannelEventDataEncodeDelegate eventDataEncodeDelegate;

  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;

  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PrivateEncryptedChannelAuthorizationData> authorizationDelegate;

  @override
  final ChannelPublicEventEmitter publicEventEmitter;

  @override
  final String name;

  @override
  final ChannelsManagerStreamGetter publicStreamGetter;

  @internal
  PrivateEncryptedChannel.internal({
    required this.publicStreamGetter,
    required this.publicEventEmitter,
    required this.connectionDelegate,
    required this.name,
    required this.authorizationDelegate,
    required this.eventDataEncodeDelegate,
  });

  /// Unlike the public channels, this channel:
  /// 1. Grabs the authorization data of type [PrivateEncryptedChannelAuthorizationData].
  /// 2. Sends the subscription event with the derived data.
  /// 3. Shared secret is accessible from [authData] for further internal decryption of the event data.
  ///
  /// See also:
  /// - [EndpointAuthorizableChannelAuthorizationDelegate]
  /// - [EndpointAuthorizableChannel]
  @override
  void subscribe() async {
    super.subscribe();
    final fixatedLifeCycleCount = startNewAuthRequestCycle();
    await setAuthKeyFromDelegate();
    final currentAuthKey = authData?.authKey;
    if (fixatedLifeCycleCount < authRequestCycle ||
        currentAuthKey == null ||
        state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent.forPrivateEncryptedChannel(
        channelName: name,
        authKey: currentAuthKey,
      ),
    );
  }

  /// Sends the unsubscription event through the [connectionDelegate].
  @override
  void unsubscribe() {
    connectionDelegate.sendEvent(
      ChannelUnsubscribeEvent(
        channelName: name,
      ),
    );
    super.unsubscribe();
  }

  @override
  PrivateEncryptedChannelState getStateWithNewStatus(ChannelStatus status) =>
      _stateIfNull().copyWith(
        status: status,
      );

  @override
  PrivateEncryptedChannelState getStateWithNewSubscriptionCount(
    int? subscriptionCount,
  ) =>
      _stateIfNull().copyWith(
        subscriptionCount: subscriptionCount,
      );

  /// Emits the event using [publicEventEmitter] if it managed to decrypt the event data successfully.
  @override
  void handleOtherExternalEvents(ChannelReadEvent readEvent) {
    final sharedSecret = authData?.sharedSecret;
    if (readEvent.name.contains(Channel.pusherInternalPrefix) ||
        sharedSecret == null) {
      return;
    }

    String? errorMessage;
    dynamic arosedException;
    StackTrace? stackTrace;

    try {
      publicEventEmitter(
        ChannelReadEvent.fromPusherChannelsReadEvent(
          this,
          readEvent.copyWithDecryptedData(
            key: sharedSecret,
            encodeDelegate: eventDataEncodeDelegate,
          ),
        ),
      );
      return;
    } on PusherChannelsException catch (exception, trace) {
      stackTrace = trace;
      arosedException = exception;
      errorMessage = exception.message;
    } catch (exception, trace) {
      stackTrace = trace;
      arosedException = exception;
      errorMessage = 'Failed to process the encrypted event';
    }

    errorMessage =
        '$errorMessage\nChannel:$name\nException:$arosedException\nTrace:$stackTrace';

    PusherChannelsPackageLogger.log(errorMessage);
  }

  @internal
  static String defaultEventDataEncoder(Uint8List bytes) => utf8.decode(bytes);

  PrivateEncryptedChannelState _stateIfNull() =>
      state ?? PrivateEncryptedChannelState.initial();
}
