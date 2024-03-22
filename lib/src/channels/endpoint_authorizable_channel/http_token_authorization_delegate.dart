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

class _ParsingException implements PusherChannelsException {
  @override
  final String message;

  const _ParsingException._({
    required this.message,
  });

  const _ParsingException.failedToGetAuthKey()
      : this._(
          message:
              'Failed to retrieve auth key from the authorization endpoint',
        );

  const _ParsingException.failedToGetSharedSecret()
      : this._(
          message:
              'Failed to retrieve shared_secret from the authorization endpoint',
        );

  const _ParsingException.failedToGetChannelData()
      : this._(
          message:
              'Failed to retrieve channel_data from the authorization endpoint',
        );

  const _ParsingException.failedToDecodeSharedSecret()
      : this._(
          message: 'Failed to decode the shared_secret',
        );

  const _ParsingException.invalidResponse()
      : this._(
          message: 'Invalid response. Expected a response of type JSON',
        );
}

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
  final bool overrideContentTypeHeader;

  @protected
  final EndpointAuthorizableChannelTokenAuthorizationParser<T> parser;
  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  const EndpointAuthorizableChannelTokenAuthorizationDelegate._({
    required this.overrideContentTypeHeader,
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
        if (overrideContentTypeHeader)
          'content-type': 'application/x-www-form-urlencoded',
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
  /// Set `overrideContentTypeHeader` to `false` in order to prevent
  /// `'content-type': 'application/x-www-form-urlencoded'` from being added into provided `headers`.
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
    bool overrideContentTypeHeader = true,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateChannelAuthorizationData>
        parser = _defaultParserForPrivateChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        overrideContentTypeHeader: overrideContentTypeHeader,
        authorizationEndpoint: authorizationEndpoint,
        onAuthFailed: onAuthFailed,
        headers: headers,
        parser: parser,
      );

  /// Providing an instance of this class to authorize
  /// to [PrivateEncryptedChannel]s with [PrivateEncryptedChannelAuthorizationData].
  ///
  /// Set `overrideContentTypeHeader` to `false` in order to prevent
  /// `'content-type': 'application/x-www-form-urlencoded'` from being added into provided `headers`.
  ///
  /// If the custom [parser] is not provided the default one will
  /// be used:
  ///
  /// ```dart
  /// static PrivateEncryptedChannelAuthorizationData
  ///     _defaultParserForPrivateEncryptedChannel(http.Response response) {
  ///   final decoded = jsonDecode(response.body) as Map;
  ///   final auth = decoded['auth'] as String;
  ///   final sharedSecret = decoded['shared_secret'] as String;
  ///   final key = base64Decode(sharedSecret);

  ///   return PrivateEncryptedChannelAuthorizationData(
  ///     authKey: auth,
  ///     sharedSecret: key,
  ///   );
  /// }
  /// ```
  static EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PrivateEncryptedChannelAuthorizationData> forPrivateEncryptedChannel({
    required Uri authorizationEndpoint,
    required Map<String, String> headers,
    bool overrideContentTypeHeader = true,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateEncryptedChannelAuthorizationData>
        parser = _defaultParserForPrivateEncryptedChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        authorizationEndpoint: authorizationEndpoint,
        overrideContentTypeHeader: overrideContentTypeHeader,
        headers: headers,
        parser: parser,
        onAuthFailed: onAuthFailed,
      );

  /// Providing an instance of this class to authorize
  /// to [PresenceChannel]s with [PresenceChannelAuthorizationData].
  ///
  /// Set `overrideContentTypeHeader` to `false` in order to prevent
  /// `'content-type': 'application/x-www-form-urlencoded'` from being added into provided `headers`.
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
    bool overrideContentTypeHeader = true,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PresenceChannelAuthorizationData>
        parser = _defaultParserForPresenceChannel,
    EndpointAuthFailedCallback? onAuthFailed,
  }) =>
      EndpointAuthorizableChannelTokenAuthorizationDelegate._(
        authorizationEndpoint: authorizationEndpoint,
        overrideContentTypeHeader: overrideContentTypeHeader,
        headers: headers,
        parser: parser,
        onAuthFailed: onAuthFailed,
      );

  static PrivateEncryptedChannelAuthorizationData
      _defaultParserForPrivateEncryptedChannel(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const _ParsingException.invalidResponse();
    }

    final auth = decoded['auth'];
    final sharedSecret = decoded['shared_secret'];

    if (auth is! String) {
      throw const _ParsingException.failedToGetAuthKey();
    }
    if (sharedSecret is! String) {
      throw const _ParsingException.failedToGetSharedSecret();
    }

    try {
      final key = base64Decode(sharedSecret);

      return PrivateEncryptedChannelAuthorizationData(
        authKey: auth,
        sharedSecret: key,
      );
    } catch (_) {
      throw const _ParsingException.failedToDecodeSharedSecret();
    }
  }

  static PrivateChannelAuthorizationData _defaultParserForPrivateChannel(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const _ParsingException.invalidResponse();
    }

    final auth = decoded['auth'];

    if (auth is! String) {
      throw const _ParsingException.failedToGetAuthKey();
    }

    return PrivateChannelAuthorizationData(
      authKey: auth,
    );
  }

  static PresenceChannelAuthorizationData _defaultParserForPresenceChannel(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const _ParsingException.invalidResponse();
    }

    final auth = decoded['auth'];
    final channelData = decoded['channel_data'];

    if (auth is! String) {
      throw const _ParsingException.failedToGetAuthKey();
    }
    if (channelData is! String) {
      throw const _ParsingException.failedToGetChannelData();
    }

    return PresenceChannelAuthorizationData(
      authKey: auth,
      channelDataEncoded: channelData,
    );
  }
}
