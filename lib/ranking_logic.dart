import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

int rankingAsInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String rankTierFromPoints(int points) {
  if (points >= 8000) return 'S';
  if (points >= 5000) return 'A';
  if (points >= 3000) return 'B';
  if (points >= 1000) return 'C';
  if (points >= 500) return 'D';
  return 'E';
}

int levelFromPoints(int points) => 1 + (points ~/ 500);

String hunterNameFromAuth(User? user) {
  if (user == null) return 'Unknown Hunter';
  final display = user.displayName?.trim();
  if (display != null && display.isNotEmpty) return display;
  final email = user.email?.trim();
  if (email != null && email.contains('@')) {
    return email.split('@').first;
  }
  return 'Hunter';
}

String resolveHunterName(Map<dynamic, dynamic> data, {String? fallback}) {
  final stored = data['name']?.toString().trim();
  if (stored != null && stored.isNotEmpty) return stored;
  final fallbackName = fallback?.trim();
  if (fallbackName != null && fallbackName.isNotEmpty) return fallbackName;
  return 'Unknown Hunter';
}

Future<void> syncHunterNameToDatabase() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final name = hunterNameFromAuth(user);
  await FirebaseDatabase.instance.ref('users/${user.uid}/name').set(name);
}

class RankedHunter {
  final String uid;
  final String name;
  final int points;
  final int level;
  final String rank;
  final int overallRating;

  const RankedHunter({
    required this.uid,
    required this.name,
    required this.points,
    required this.level,
    required this.rank,
    required this.overallRating,
  });

  factory RankedHunter.fromSnapshot(
    String uid,
    Map<dynamic, dynamic> data, {
    String? nameFallback,
  }) {
    final points = rankingAsInt(data['points']);
    return RankedHunter(
      uid: uid,
      name: resolveHunterName(data, fallback: nameFallback),
      points: points,
      level: data['level'] != null ? rankingAsInt(data['level'], 1) : levelFromPoints(points),
      rank: data['rank']?.toString() ?? rankTierFromPoints(points),
      overallRating: rankingAsInt(data['overallRating']),
    );
  }
}

int compareHunters(RankedHunter a, RankedHunter b) {
  final byPoints = b.points.compareTo(a.points);
  if (byPoints != 0) return byPoints;
  final byLevel = b.level.compareTo(a.level);
  if (byLevel != 0) return byLevel;
  final byRating = b.overallRating.compareTo(a.overallRating);
  if (byRating != 0) return byRating;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

List<RankedHunter> buildLeaderboard(
  Map<dynamic, dynamic>? usersData, {
  String? currentUid,
  String? currentUserName,
}) {
  if (usersData == null) return [];

  final hunters = <RankedHunter>[];
  usersData.forEach((key, value) {
    if (value is Map) {
      final uid = key.toString();
      final fallback = uid == currentUid ? currentUserName : null;
      hunters.add(RankedHunter.fromSnapshot(
        uid,
        Map<dynamic, dynamic>.from(value),
        nameFallback: fallback,
      ));
    }
  });

  hunters.sort(compareHunters);
  return hunters;
}

int? positionForUser(List<RankedHunter> leaderboard, String? uid) {
  if (uid == null) return null;
  final index = leaderboard.indexWhere((h) => h.uid == uid);
  return index >= 0 ? index + 1 : null;
}

RankedHunter? hunterForUser(List<RankedHunter> leaderboard, String? uid) {
  if (uid == null) return null;
  for (final hunter in leaderboard) {
    if (hunter.uid == uid) return hunter;
  }
  return null;
}

String rankSubtitle(int position, int total) {
  if (total <= 1) return 'SOLO HUNTER ACTIVE';
  final percentile = ((position / total) * 100).ceil().clamp(1, 100);
  if (position == 1) return 'TOP 1 — SOVEREIGN';
  if (percentile <= 10) return 'TOP $percentile% ELITE';
  if (percentile <= 25) return 'TOP $percentile% VETERAN';
  if (percentile <= 50) return 'TOP $percentile% RISING';
  return 'CLIMB THE LADDER';
}
