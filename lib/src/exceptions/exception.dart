import 'package:meta/meta.dart';

@immutable
class PusherException implements Exception {
  final dynamic error;
  final StackTrace? stackTrace;

  PusherException({this.error, this.stackTrace});
}
