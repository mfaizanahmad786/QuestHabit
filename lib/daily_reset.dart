import 'package:firebase_database/firebase_database.dart';

/// Local calendar date key (yyyy-MM-dd) for daily quest resets.
String todayDateKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  final y = d.year.toString();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int _daysBetweenDateKeys(String fromKey, String toKey) {
  try {
    final from = DateTime.parse(fromKey);
    final to = DateTime.parse(toKey);
    return DateTime(to.year, to.month, to.day)
        .difference(DateTime(from.year, from.month, from.day))
        .inDays;
  } catch (_) {
    return 1;
  }
}

/// Returns true if a reset was applied to Firebase.
Future<bool> applyDailyQuestResetIfNeeded({
  required DatabaseReference userRef,
  required Map<dynamic, dynamic> userData,
}) async {
  final today = todayDateKey();
  final lastReset = userData['lastQuestResetDate']?.toString();

  if (lastReset == today) return false;

  final totalDays = _asInt(userData['totalDays'], 90);
  var currentDay = _asInt(userData['currentDay'], 1);

  if (lastReset != null && lastReset.isNotEmpty) {
    final elapsed = _daysBetweenDateKeys(lastReset, today);
    if (elapsed > 0) {
      currentDay = (currentDay + elapsed).clamp(1, totalDays);
    }
  }

  await userRef.update({
    'completedQuests': [],
    'lastQuestResetDate': today,
    'currentDay': currentDay,
  });

  return true;
}
