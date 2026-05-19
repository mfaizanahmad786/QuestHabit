import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'daily_reset.dart';
import 'goal_models.dart';
import 'ranking_logic.dart';

class GoalRepository {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference? get _goalsRef {
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('users/$uid/goals');
  }

  DatabaseReference? get _userRef {
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('users/$uid');
  }

  Stream<List<AiGoal>> watchGoals() {
    final ref = _goalsRef;
    if (ref == null) return Stream.value([]);

    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <AiGoal>[];

      final goals = value.entries
          .map((e) => AiGoal.fromSnapshot(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return goals;
    });
  }

  Stream<AiGoal?> watchGoal(String goalId) {
    final ref = _goalsRef?.child(goalId);
    if (ref == null) return Stream.value(null);

    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return AiGoal.fromSnapshot(goalId, Map<dynamic, dynamic>.from(value));
    });
  }

  Future<String> saveGoal({
    required GeneratedGoalPlan plan,
    required String userIntent,
    required int timelineMonths,
  }) async {
    final ref = _goalsRef;
    if (ref == null) throw Exception('Not signed in');

    final newRef = ref.push();
    final goal = AiGoal(
      id: newRef.key!,
      title: plan.title,
      userIntent: userIntent,
      summary: plan.summary,
      timelineMonths: timelineMonths,
      targetDays: plan.targetDays,
      status: 'active',
      rewardStats: plan.rewardStats,
      rewardPoints: plan.rewardPoints,
      quests: plan.quests,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await newRef.set(goal.toCreateMap());
    return newRef.key!;
  }

  /// Log today's completion for a daily goal quest (once per calendar day).
  Future<void> logQuestToday({
    required String goalId,
    required String questId,
    required bool logToday,
  }) async {
    final questRef = _goalsRef?.child('$goalId/quests/$questId');
    if (questRef == null) return;

    final snap = await questRef.get();
    if (!snap.exists || snap.value is! Map) return;

    final data = Map<dynamic, dynamic>.from(snap.value as Map);
    final today = todayDateKey();
    var days = rankingAsInt(data['daysCompleted']);
    final lastLogged = data['lastLoggedDate']?.toString();

    if (logToday) {
      if (lastLogged != today) {
        days += 1;
        await questRef.update({
          'completed': true,
          'daysCompleted': days,
          'lastLoggedDate': today,
        });
      } else {
        await questRef.update({'completed': true});
      }
    } else {
      if (lastLogged == today && days > 0) {
        days -= 1;
        await questRef.update({
          'completed': false,
          'daysCompleted': days,
        });
        await questRef.child('lastLoggedDate').remove();
      } else {
        await questRef.update({'completed': false});
      }
    }
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalsRef?.child(goalId).remove();
  }

  Future<void> claimGoalCompletion(String goalId) async {
    final userRef = _userRef;
    final goalRef = _goalsRef?.child(goalId);
    if (userRef == null || goalRef == null) throw Exception('Not signed in');

    final goalSnap = await goalRef.get();
    if (!goalSnap.exists || goalSnap.value is! Map) {
      throw Exception('Goal not found');
    }

    final goal = AiGoal.fromSnapshot(goalId, Map<dynamic, dynamic>.from(goalSnap.value as Map));
    if (!goal.allQuestsDone) {
      throw Exception('Log every daily habit for ${goal.targetDays} days before claiming');
    }
    if (goal.isCompleted) {
      throw Exception('Rewards already claimed');
    }

    final userSnap = await userRef.get();
    final userData = userSnap.exists && userSnap.value is Map
        ? Map<dynamic, dynamic>.from(userSnap.value as Map)
        : <dynamic, dynamic>{};

    Map<String, dynamic> currentStats = {};
    if (userData['stats'] is Map) {
      (userData['stats'] as Map).forEach((k, v) {
        currentStats[k.toString()] = rankingAsInt(v, 10);
      });
    } else {
      for (final key in goalStatKeys) {
        currentStats[key] = 10;
      }
    }

    for (final key in goalStatKeys) {
      final bonus = goal.rewardStats[key] ?? 0;
      currentStats[key] = rankingAsInt(currentStats[key]) + bonus;
    }

    final currentPoints = rankingAsInt(userData['points']);
    final newPoints = currentPoints + goal.rewardPoints;

    await userRef.update({
      'stats': currentStats,
      'points': newPoints,
      'level': levelFromPoints(newPoints),
      'rank': rankTierFromPoints(newPoints),
    });

    await goalRef.update({'status': 'completed'});
  }
}
