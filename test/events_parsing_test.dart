import 'dart:convert';

import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group(
    'PusherChannelsConnectionEstablishedEvent |',
    () {
      test(
        'testing members of PusherChannelsConnectionEstablishedEvent',
        () {
          final mapMessage = {
            'event': 'pusher:connection_established',
            'data': jsonEncode(<String, String>{
              'socket_id': '123',
              'activity_timeout': '12',
            })
          };
          final event =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessage,
          );
          expect(
            event?.activityTimeoutDuration?.inSeconds,
            12,
          );
        },
      );
      test(
        '.tryParseFromDynamic gives null if message not String or Map, if wrong event name, if socketId is null',
        () {
          final mapMessage = {
            'event': 'pusher:connection_established',
            'data': jsonEncode(<String, dynamic>{
              'socket_id': 12,
            })
          };
          final mapMessageNoSocketId = {
            'event': 'pusher:connection_established',
            'data': jsonEncode(<String, dynamic>{})
          };
          final mapMessageWrong = {
            'event': 'pusher:connection_established1',
            'data': jsonEncode(<String, String>{})
          };
          final stringMessage = jsonEncode(
            mapMessage,
          );
          final wrongMessage = 1;

          final mustBeNull =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            wrongMessage,
          );

          final fromMap =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessage,
          );

          final fromString =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            stringMessage,
          );

          final withWrongName =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessageWrong,
          );

          final withoudSocketId =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessageNoSocketId,
          );

          expect(
            mustBeNull,
            null,
          );
          expect(
            fromMap,
            isNot(null),
          );
          expect(
            fromString,
            isNot(null),
          );
          expect(
            withWrongName,
            null,
          );
          expect(
            withoudSocketId,
            null,
          );
        },
      );
    },
  );
}
