import 'goal_models.dart';

/// Offline daily-habit plans when the AI API is unavailable.
class FallbackGoalService {
  GeneratedGoalPlan generate({
    required String userIntent,
    required int timelineMonths,
  }) {
    final intent = userIntent.toLowerCase();
    final targetDays = targetDaysForTimeline(timelineMonths);
    final count = timelineMonths <= 1 ? 4 : (timelineMonths == 2 ? 5 : 6);

    if (intent.contains('smok') || intent.contains('vape') || intent.contains('nicotine')) {
      return _plan(
        title: 'SMOKE-FREE PROTOCOL',
        summary:
            'Daily smoke-free habits for: $userIntent. Log each habit every day for $targetDays days.',
        intent: intent,
        months: timelineMonths,
        count: count,
        targetDays: targetDays,
        habits: const [
          ('DAILY: DELAY CRAVING', 'Every day, when you crave a cigarette, wait 10 minutes first.'),
          ('DAILY: WALK BREAK', 'Every day, replace one smoke break with a 5-minute walk.'),
          ('DAILY: WATER SWAP', 'Every day, drink a glass of water instead of smoking after one meal.'),
          ('DAILY: BREATH RESET', 'Every day, do 5 minutes of box-breathing when stressed.'),
          ('DAILY: REDUCE COUNT', 'Every day, smoke at least one fewer cigarette than yesterday.'),
          ('DAILY: MORNING CLEAN', 'Every day, keep the first hour after waking smoke-free.'),
        ],
        stats: {'STRENGTH': 5, 'WISDOM': 10, 'VITALITY': 25, 'STAMINA': 20},
      );
    }
    if (intent.contains('sugar') || intent.contains('sweet') || intent.contains('candy')) {
      return _plan(
        title: 'SUGAR DETOX PROTOCOL',
        summary:
            'Daily low-sugar habits for: $userIntent. Log each habit every day for $targetDays days.',
        intent: intent,
        months: timelineMonths,
        count: count,
        targetDays: targetDays,
        habits: const [
          ('DAILY: NO SODA', 'Every day, drink only water or unsweetened tea instead of soda.'),
          ('DAILY: ZERO SWEETS AT BREAKFAST', 'Every day, eat a savory or protein breakfast with no sugar.'),
          ('DAILY: HEALTHY SNACK', 'Every day, swap one sugary snack for fruit or nuts.'),
          ('DAILY: READ LABELS', 'Every day, check one food label and avoid sugar in the top 3 ingredients.'),
          ('DAILY: POST-MEAL WALK', 'Every day, walk 10 minutes after lunch or dinner.'),
          ('DAILY: NO DESSERT', 'Every day, skip dessert after your evening meal.'),
        ],
        stats: {'STRENGTH': 5, 'WISDOM': 15, 'VITALITY': 20, 'STAMINA': 10},
      );
    }
    if (intent.contains('gym') || intent.contains('run') || intent.contains('fit')) {
      return _plan(
        title: 'PHYSICAL ASCENSION',
        summary:
            'Daily movement habits for: $userIntent. Log each habit every day for $targetDays days.',
        intent: intent,
        months: timelineMonths,
        count: count,
        targetDays: targetDays,
        habits: const [
          ('DAILY: STEPS', 'Every day, walk at least 6,000 steps.'),
          ('DAILY: BODYWEIGHT', 'Every day, do 3 sets of squats, push-ups, and a 30s plank.'),
          ('DAILY: HYDRATE', 'Every day, drink at least 2L of water.'),
          ('DAILY: STRETCH', 'Every day, stretch for 10 minutes after waking or before bed.'),
          ('DAILY: SLEEP', 'Every day, get at least 7 hours of sleep.'),
          ('DAILY: PROTEIN MEAL', 'Every day, eat one high-protein meal after activity.'),
        ],
        stats: {'STRENGTH': 25, 'WISDOM': 5, 'VITALITY': 15, 'STAMINA': 20},
      );
    }
    return _plan(
      title: 'CUSTOM SOVEREIGN GOAL',
      summary:
          'Daily habits for: $userIntent. Log each habit every day for $targetDays days.',
      intent: intent,
      months: timelineMonths,
      count: count,
      targetDays: targetDays,
      habits: const [
        ('DAILY: MINIMUM ACTION', 'Every day, do the smallest version of your habit.'),
        ('DAILY: TRACK IT', 'Every day, mark your habit complete in the app.'),
        ('DAILY: PREP TONIGHT', 'Every day, prepare what you need for tomorrow\'s habit.'),
        ('DAILY: REMOVE FRICTION', 'Every day, remove one obstacle that blocks your habit.'),
        ('DAILY: RECOVERY', 'Every day, if you slipped yesterday, complete today\'s habit anyway.'),
        ('DAILY: REVIEW', 'Every day, spend 2 minutes reviewing why this habit matters.'),
      ],
      stats: {'STRENGTH': 10, 'WISDOM': 10, 'VITALITY': 10, 'STAMINA': 10},
    );
  }

  GeneratedGoalPlan _plan({
    required String title,
    required String summary,
    required String intent,
    required int months,
    required int count,
    required int targetDays,
    required List<(String, String)> habits,
    required Map<String, int> stats,
  }) {
    final quests = <GoalQuest>[];
    for (var i = 0; i < count; i++) {
      final h = habits[i % habits.length];
      quests.add(GoalQuest(id: 'q$i', title: h.$1, desc: h.$2, weekIndex: 1));
    }
    return GeneratedGoalPlan(
      title: title,
      summary: summary,
      rewardStats: stats,
      rewardPoints: 150 + months * 50,
      quests: quests,
      targetDays: targetDays,
    );
  }
}
