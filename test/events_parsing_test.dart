// ignore_for_file: require_trailing_commas

import 'dart:convert';

import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/ping_event.dart';
import 'package:dart_pusher_channels/src/events/pong_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

// Ignoring for testing
// ignore: long-method
void main() {
  group(
    'PusherChannelsReadEvent',
    () {
      test(
        'getters name and data must be respective to the one from rootObject',
        () {
          final event = jsonEncode({
            'event': 'hello',
            'data': jsonEncode(
              {
                'payload': 3,
              },
            )
          });
          final readEvent = PusherChannelsReadEvent.tryParseFromDynamic(
            event,
          );
          expect(readEvent?.name, 'hello');
          expect(readEvent?.data, isA<String>());
          expect(readEvent?.data, '{"payload":3}');
        },
      );
    },
  );
  group(
    'PusherChannelsPongEvent |',
    () {
      test(
        'tryParseFromDynamic gives null if message not String or Map, if wrong event name',
        () {
          final mapMessage = {
            'event': 'pusher:pong',
            'data': jsonEncode(<String, dynamic>{})
          };
          final mapMessageWrong = {
            'event': 'pusher:pong1',
            'data': jsonEncode(<String, String>{})
          };
          final stringMessage = jsonEncode(
            mapMessage,
          );
          final wrongMessage = 1;

          final mustBeNull = PusherChannelsPongEvent.tryParseFromDynamic(
            wrongMessage,
          );

          final fromMap = PusherChannelsPongEvent.tryParseFromDynamic(
            mapMessage,
          );

          final fromString = PusherChannelsPongEvent.tryParseFromDynamic(
            stringMessage,
          );

          final withWrongName = PusherChannelsPongEvent.tryParseFromDynamic(
            mapMessageWrong,
          );

          expect(
            mustBeNull,
            null,
          );
          expect(
            fromMap,
            isA<PusherChannelsPongEvent>(),
          );
          expect(
            fromString,
            isA<PusherChannelsPongEvent>(),
          );
          expect(
            withWrongName,
            null,
          );
        },
      );
    },
  );
  group(
    'PusherChannelsPingEvent |',
    () {
      test(
        'tryParseFromDynamic gives null if message not String or Map, if wrong event name',
        () {
          final mapMessage = {
            'event': 'pusher:ping',
            'data': jsonEncode(<String, dynamic>{})
          };
          final mapMessageWrong = {
            'event': 'pusher:ping1',
            'data': jsonEncode(<String, String>{})
          };
          final stringMessage = jsonEncode(
            mapMessage,
          );
          final wrongMessage = 1;

          final mustBeNull = PusherChannelsPingEvent.tryParseFromDynamic(
            wrongMessage,
          );

          final fromMap = PusherChannelsPingEvent.tryParseFromDynamic(
            mapMessage,
          );

          final fromString = PusherChannelsPingEvent.tryParseFromDynamic(
            stringMessage,
          );

          final withWrongName = PusherChannelsPingEvent.tryParseFromDynamic(
            mapMessageWrong,
          );

          expect(fromMap?.name, 'pusher:ping');

          expect(
            mustBeNull,
            null,
          );
          expect(
            fromMap,
            isA<PusherChannelsPingEvent>(),
          );
          expect(
            fromString,
            isA<PusherChannelsPingEvent>(),
          );
          expect(
            withWrongName,
            null,
          );
        },
      );
    },
  );
  group('PusherChannelsErrorEvent |', () {
    test(
      'testing members of PusherChannelsErrorEvent',
      () {
        final mapMessage = {
          'event': 'pusher:error',
          'data': jsonEncode(<String, String>{
            'code': '123',
            'message': 'hello',
          })
        };
        final event = PusherChannelsErrorEvent.tryParseFromDynamic(
          mapMessage,
        );

        expect(event?.name, 'pusher:error');

        expect(
          event?.code,
          123,
        );
        expect(
          event?.message,
          'hello',
        );
      },
    );
    test(
      '.tryParseFromDynamic gives null if message not String or Map, if wrong event name',
      () {
        final mapMessage = {
          'event': 'pusher:error',
          'data': jsonEncode(<String, dynamic>{})
        };
        final mapMessageWrong = {
          'event': 'pusher:error1',
          'data': jsonEncode(<String, String>{})
        };
        final stringMessage = jsonEncode(
          mapMessage,
        );
        final wrongMessage = 1;

        final mustBeNull = PusherChannelsErrorEvent.tryParseFromDynamic(
          wrongMessage,
        );

        final fromMap = PusherChannelsErrorEvent.tryParseFromDynamic(
          mapMessage,
        );

        final fromString = PusherChannelsErrorEvent.tryParseFromDynamic(
          stringMessage,
        );

        final withWrongName = PusherChannelsErrorEvent.tryParseFromDynamic(
          mapMessageWrong,
        );

        expect(
          mustBeNull,
          null,
        );
        expect(
          fromMap,
          isA<PusherChannelsErrorEvent>(),
        );
        expect(
          fromString,
          isA<PusherChannelsErrorEvent>(),
        );
        expect(
          withWrongName,
          null,
        );
      },
    );
  });
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
          expect(event?.socketId, '123');
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
          final mapMessageWrongName = {
            'event': 'pusher:connection_established1',
            'data': jsonEncode(<String, String>{})
          };
          final mapMessageWrongData = {
            'event': 'pusher:connection_established1',
            'data': 3
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
            mapMessageWrongName,
          );

          final withWrongData =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessageWrongData,
          );

          final withoudSocketId =
              PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
            mapMessageNoSocketId,
          );

          expect(fromMap?.name, 'pusher:connection_established');

          expect(
            mustBeNull,
            null,
          );
          expect(
            fromMap,
            isA<PusherChannelsConnectionEstablishedEvent>(),
          );
          expect(
            fromString,
            isA<PusherChannelsConnectionEstablishedEvent>(),
          );
          expect(
            withWrongName,
            null,
          );
          expect(
            withoudSocketId,
            null,
          );
          expect(
            withWrongData,
            null,
          );
        },
      );
    },
  );
}
