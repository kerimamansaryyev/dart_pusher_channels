import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/utils/event_names.dart';
import 'package:meta/meta.dart';

import '../utils/helpers.dart';

@immutable
class PusherChannelsErrorEvent implements PusherChannelsEvent {
  static const _codeKey = 'code';
  static const _messageKey = 'message';
  static const _name = PusherChannelsEventNames.error;

  final int? code;
  final String? message;

  @override
  final String name = PusherChannelsEventNames.error;

  const PusherChannelsErrorEvent._({
    required this.code,
    required this.message,
  });

  static PusherChannelsErrorEvent? tryParseFromDynamic(dynamic message) {
    final root = safeMessageToMapDeserializer(message);
    final name = root?[PusherChannelsEvent.eventNameKey]?.toString();
    if (root == null || name != _name) {
      return null;
    }

    final data = safeMessageToMapDeserializer(
      root[PusherChannelsEvent.dataKey],
    );

    final code = int.tryParse(
      data?[_codeKey]?.toString() ?? '',
    );
    final errorMessage = data?[_messageKey]?.toString();

    return PusherChannelsErrorEvent._(
      code: code,
      message: errorMessage,
    );
  }
}
