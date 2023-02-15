import 'dart:async';
import 'dart:convert';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_encrypted_channel.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
import 'package:http/http.dart' as http;
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:meta/meta.dart';

typedef EndpointAuthorizableChannelTokenAuthorizationParser<
        T extends EndpointAuthorizationData>
    = FutureOr<T> Function(http.Response response);

/// [EndpointAuthorizableChannelTokenAuthorizationDelegate] will
/// throw this exception if it gets irrelevant response from
/// the [authorizationEndpoint].
class EndpointAuthorizableChannelTokenAuthorizationException
    implements PusherChannelsException {
  final http.Response response;
  final Uri authorizationEndpoint;

  const EndpointAuthorizableChannelTokenAuthorizationException._({
    required this.response,
    required this.authorizationEndpoint,
  });

  @override
  String get message =>
      'Failed to get authorization data. Response to $authorizationEndpoint was:\n ${response.body}';
}

/// Implements [EndpointAuthorizableChannelAuthorizationDelegate]
/// to grab the authorization data from the [authorizationEndpoint]
/// using the POST request powered by the [http](https://pub.dev/packages/http) package.
@immutable
class EndpointAuthorizableChannelTokenAuthorizationDelegate<
        T extends EndpointAuthorizationData>
    implements EndpointAuthorizableChannelAuthorizationDelegate<T> {
  final Uri authorizationEndpoint;
  final Map<String, String> headers;
  @protected
  final EndpointAuthorizableChannelTokenAuthorizationParser<T> parser;
  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  const EndpointAuthorizableChannelTokenAuthorizationDelegate._({
    required this.authorizationEndpoint,
    required this.headers,
    required this.parser,
    required this.onAuthFailed,
  });

  /// Sends the POST request to the [authorizationEndpoint].
  ///
  /// Applies the [headers] as following:
  /// ```
  /// ...
  /// headers: {
  ///   ...headers,
  ///   'content-type': 'application/x-www-form-urlencoded'
  /// },
  /// ...
  /// ```
  ///
  /// Applies the `body` as following:
  /// ```
  ///   body: {
  ///   'socket_id': socketId,
  ///   'channel_name': channelName,
  /// },
  /// ```
  ///
  @override
  Future<T> authorizationData(String socketId, String channelName) async {
    final response = await http.post(
      authorizationEndpoint,
      headers: {
        ...headers,
        'content-type': 'application/x-www-form-urlencoded'
      },
      body: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
    );

    if (response.statusCode != 200) {
      throw EndpointAuthorizableChannelTokenAuthorizationException._(
        response: response,
        authorizationEndpoint: authorizationEndpoint,
      );
    }
    return parser(response);
  }

  /// Providing an instance of this class to authorize
  /// to [PrivateChannel]s with [PrivateChannelAuthorizationData].
  ///
  /// If the custom [parser] is not provided the default one will
  /// be used:
  ///
  /// ```dart
  ///  static PrivateChannelAuthorizationData _defaultParserForPrivateChannel(
  ///   http.Response response,
  ///  ) {
  ///   final decoded = jsonDecode(response.body) as Map;
  ///   final auth = decoded['auth'] as String;

  ///   return PrivateChannelAuthorizationData(
  ///     authKey: auth,
  ///   );
  /// }
  /// ```
  static EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PrivateChannelAuthorizationData> forPrivateChannel({
    required Uri authorizationEndpoint,
    required Map<String, String> headers,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateChannelAuthorizationData>
        parser = _defaultParserForPrivateChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        authorizationEndpoint: authorizationEndpoint,
        onAuthFailed: onAuthFailed,
        headers: headers,
        parser: parser,
      );

  static EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PrivateEncryptedChannelAuthorizationData> forPrivateEncryptedChannel({
    required Uri authorizationEndpoint,
    required Map<String, String> headers,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateEncryptedChannelAuthorizationData>
        parser = _defaultParserForPrivateEncryptedChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        authorizationEndpoint: authorizationEndpoint,
        headers: headers,
        parser: parser,
        onAuthFailed: onAuthFailed,
      );

  /// Providing an instance of this class to authorize
  /// to [PresenceChannel]s with [PresenceChannelAuthorizationData].
  ///
  /// If the custom [parser] is not provided the default one will
  /// be used:
  ///
  /// ```dart
  /// static PresenceChannelAuthorizationData _defaultParserForPresenceChannel(
  ///   http.Response response,
  /// ) {
  ///   final decoded = jsonDecode(response.body) as Map;
  ///   final auth = decoded['auth'] as String;
  ///   final channelData = decoded['channel_data'] as String;

  ///   return PresenceChannelAuthorizationData(
  ///     authKey: auth,
  ///     channelDataEncoded: channelData,
  ///   );
  /// }

  /// ```
  static EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PresenceChannelAuthorizationData> forPresenceChannel({
    required Uri authorizationEndpoint,
    required Map<String, String> headers,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PresenceChannelAuthorizationData>
        parser = _defaultParserForPresenceChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        authorizationEndpoint: authorizationEndpoint,
        headers: headers,
        parser: parser,
        onAuthFailed: onAuthFailed,
      );

  static PrivateEncryptedChannelAuthorizationData
      _defaultParserForPrivateEncryptedChannel(http.Response response) {
    final decoded = jsonDecode(response.body) as Map;
    final auth = decoded['auth'] as String;
    final sharedSecret = decoded['shared_secret'] as String;
    final key = base64Decode(sharedSecret);

    return PrivateEncryptedChannelAuthorizationData(
      authKey: auth,
      sharedSecret: key,
    );
  }

  static PrivateChannelAuthorizationData _defaultParserForPrivateChannel(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body) as Map;
    final auth = decoded['auth'] as String;

    return PrivateChannelAuthorizationData(
      authKey: auth,
    );
  }

  static PresenceChannelAuthorizationData _defaultParserForPresenceChannel(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body) as Map;
    final auth = decoded['auth'] as String;
    final channelData = decoded['channel_data'] as String;

    return PresenceChannelAuthorizationData(
      authKey: auth,
      channelDataEncoded: channelData,
    );
  }
}
