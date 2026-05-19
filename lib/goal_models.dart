import 'daily_reset.dart';

const List<String> goalStatKeys = ['STRENGTH', 'WISDOM', 'VITALITY', 'STAMINA'];

/// Days each daily habit must be logged to complete the goal (7 days per month of timeline).
int targetDaysForTimeline(int timelineMonths) => (timelineMonths * 7).clamp(7, 42);

class GoalQuest {
  final String id;
  final String title;
  final String desc;
  final int weekIndex;
  final bool completed;
  final int daysCompleted;
  final String? lastLoggedDate;

  const GoalQuest({
    required this.id,
    required this.title,
    required this.desc,
    required this.weekIndex,
    this.completed = false,
    this.daysCompleted = 0,
    this.lastLoggedDate,
  });

  bool get loggedToday => lastLoggedDate == todayDateKey() && completed;

  factory GoalQuest.fromMap(String id, Map<dynamic, dynamic> data) {
    final lastLogged = data['lastLoggedDate']?.toString();
    final days = _asInt(data['daysCompleted']);
    var doneToday = data['completed'] == true;
    if (lastLogged != null && lastLogged != todayDateKey()) {
      doneToday = false;
    }
    return GoalQuest(
      id: id,
      title: data['title']?.toString() ?? 'Quest',
      desc: data['desc']?.toString() ?? '',
      weekIndex: _asInt(data['weekIndex'], 1),
      completed: doneToday,
      daysCompleted: days,
      lastLoggedDate: lastLogged,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'desc': desc,
        'weekIndex': weekIndex,
        'completed': completed,
        'daysCompleted': daysCompleted,
        if (lastLoggedDate != null) 'lastLoggedDate': lastLoggedDate,
      };
}

class AiGoal {
  final String id;
  final String title;
  final String userIntent;
  final String summary;
  final int timelineMonths;
  final int targetDays;
  final String status;
  final Map<String, int> rewardStats;
  final int rewardPoints;
  final List<GoalQuest> quests;
  final int createdAt;

  const AiGoal({
    required this.id,
    required this.title,
    required this.userIntent,
    required this.summary,
    required this.timelineMonths,
    required this.targetDays,
    required this.status,
    required this.rewardStats,
    required this.rewardPoints,
    required this.quests,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  int get totalQuests => quests.length;

  int get minDaysLogged =>
      quests.isEmpty ? 0 : quests.map((q) => q.daysCompleted).reduce((a, b) => a < b ? a : b);

  bool get allQuestsDone =>
      totalQuests > 0 && quests.every((q) => q.daysCompleted >= targetDays);

  double get overallProgress {
    if (totalQuests == 0 || targetDays == 0) return 0;
    final sum = quests.fold<double>(0, (s, q) => s + (q.daysCompleted / targetDays).clamp(0.0, 1.0));
    return (sum / totalQuests).clamp(0.0, 1.0);
  }

  factory AiGoal.fromSnapshot(String id, Map<dynamic, dynamic> data) {
    final quests = <GoalQuest>[];
    final questsRaw = data['quests'];
    if (questsRaw is Map) {
      questsRaw.forEach((key, value) {
        if (value is Map) {
          quests.add(GoalQuest.fromMap(key.toString(), value));
        }
      });
    }
    quests.sort((a, b) => a.weekIndex.compareTo(b.weekIndex));

    final statsRaw = data['rewardStats'];
    final rewardStats = <String, int>{};
    if (statsRaw is Map) {
      for (final key in goalStatKeys) {
        rewardStats[key] = _asInt(statsRaw[key]);
      }
    }

    final months = _asInt(data['timelineMonths'], 1);

    return AiGoal(
      id: id,
      title: data['title']?.toString() ?? 'Goal',
      userIntent: data['userIntent']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      timelineMonths: months,
      targetDays: _asInt(data['targetDays'], targetDaysForTimeline(months)),
      status: data['status']?.toString() ?? 'active',
      rewardStats: rewardStats,
      rewardPoints: _asInt(data['rewardPoints']),
      quests: quests,
      createdAt: _asInt(data['createdAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    final questsMap = <String, dynamic>{};
    for (final q in quests) {
      questsMap[q.id] = q.toMap();
    }
    return {
      'title': title,
      'userIntent': userIntent,
      'summary': summary,
      'timelineMonths': timelineMonths,
      'targetDays': targetDays,
      'status': status,
      'rewardStats': rewardStats,
      'rewardPoints': rewardPoints,
      'createdAt': createdAt,
      'quests': questsMap,
    };
  }
}

class GeneratedGoalPlan {
  final String title;
  final String summary;
  final Map<String, int> rewardStats;
  final int rewardPoints;
  final List<GoalQuest> quests;
  final int targetDays;

  const GeneratedGoalPlan({
    required this.title,
    required this.summary,
    required this.rewardStats,
    required this.rewardPoints,
    required this.quests,
    required this.targetDays,
  });

  factory GeneratedGoalPlan.fromJson(Map<String, dynamic> json, int timelineMonths) {
    final stats = <String, int>{};
    final statsJson = json['rewardStats'];
    if (statsJson is Map) {
      for (final key in goalStatKeys) {
        stats[key] = _clampStat(_asInt(statsJson[key]));
      }
    }

    final quests = <GoalQuest>[];
    final questsJson = json['quests'];
    if (questsJson is List) {
      for (var i = 0; i < questsJson.length; i++) {
        final item = questsJson[i];
        if (item is Map) {
          quests.add(
            GoalQuest(
              id: 'q$i',
              title: item['title']?.toString() ?? 'Daily Quest ${i + 1}',
              desc: item['desc']?.toString() ?? '',
              weekIndex: 1,
            ),
          );
        }
      }
    }

    return GeneratedGoalPlan(
      title: json['title']?.toString() ?? 'Custom Goal',
      summary: json['summary']?.toString() ?? '',
      rewardStats: stats,
      rewardPoints: _clampPoints(_asInt(json['rewardPoints'], 250)),
      quests: quests,
      targetDays: targetDaysForTimeline(timelineMonths),
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int _clampStat(int v) => v.clamp(0, 25);

int _clampPoints(int v) => v.clamp(100, 500);
