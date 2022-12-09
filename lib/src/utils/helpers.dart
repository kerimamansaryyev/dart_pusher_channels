import 'dart:convert';

Map<String, dynamic>? safeMessageToMapDeserializer(dynamic message) {
  if (message is Map) {
    return leaveOnlyStringKeys(message);
  } else if (message is String) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map) {
        return leaveOnlyStringKeys(decoded);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

Map<String, dynamic> leaveOnlyStringKeys(Map other) {
  final copy = {...other}..removeWhere((key, value) => key is! String);
  return {...copy};
}
