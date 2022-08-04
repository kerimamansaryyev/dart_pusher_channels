import 'dart:async';

/// Util function that grabs all printed logs made on
/// [print]
T grabLogs<T>(T Function(List<String> printedLogs) callback) {
  final printedLogs = <String>[];
  return runZoned(
    () => callback(printedLogs),
    zoneSpecification: ZoneSpecification(
      print: (s, p, z, line) {
        printedLogs.add(line);
      },
    ),
  );
}
