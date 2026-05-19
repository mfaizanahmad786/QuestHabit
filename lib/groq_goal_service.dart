import 'dart:convert';

import 'package:http/http.dart' as http;

import 'env_config.dart';
import 'fallback_goal_service.dart';
import 'goal_models.dart';

class GoalGenerationResult {
  final GeneratedGoalPlan plan;
  final bool usedOfflineFallback;
  final String? notice;

  const GoalGenerationResult({
    required this.plan,
    this.usedOfflineFallback = false,
    this.notice,
  });
}

class GroqGoalService {
  final _fallback = FallbackGoalService();

  Future<GoalGenerationResult> generateGoalPlan({
    required String userIntent,
    required int timelineMonths,
  }) async {
    if (!EnvConfig.hasGroqKey) {
      return GoalGenerationResult(
        plan: _fallback.generate(userIntent: userIntent, timelineMonths: timelineMonths),
        usedOfflineFallback: true,
        notice: 'No API key — using offline protocol generator.',
      );
    }

    try {
      final plan = await _callGroq(userIntent: userIntent, timelineMonths: timelineMonths);
      return GoalGenerationResult(plan: plan);
    } catch (e) {
      if (_isQuotaError(e)) {
        return GoalGenerationResult(
          plan: _fallback.generate(userIntent: userIntent, timelineMonths: timelineMonths),
          usedOfflineFallback: true,
          notice: 'Groq rate limit reached. Using offline daily-habit generator.',
        );
      }
      rethrow;
    }
  }

  bool _isQuotaError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('quota') ||
        msg.contains('rate limit') ||
        msg.contains('too many requests');
  }

  Future<GeneratedGoalPlan> _callGroq({
    required String userIntent,
    required int timelineMonths,
  }) async {
    final habitCount = timelineMonths <= 1 ? 4 : (timelineMonths == 2 ? 5 : 6);
    final targetDays = targetDaysForTimeline(timelineMonths);

    final prompt = '''
Design a daily-habit goal plan for: "$userIntent"
Timeline: $timelineMonths months. User logs EACH habit EVERY DAY.

Return ONLY valid JSON:
{
  "title": "short goal name",
  "summary": "two sentences explaining daily logging over $targetDays days",
  "rewardStats": { "STRENGTH": 0-25, "WISDOM": 0-25, "VITALITY": 0-25, "STAMINA": 0-25 },
  "rewardPoints": 100-500,
  "quests": [{ "title": "DAILY: ...", "desc": "Every day, ..." }]
}

CRITICAL RULES:
- Generate exactly $habitCount quests — each is a REPEATABLE DAILY action.
- Titles MUST start with "DAILY:" (e.g. "DAILY: NO SODA", "DAILY: 10 MIN WALK").
- Descriptions MUST say "Every day" and describe what to do that same day, every day.
- FORBIDDEN: one-time setup tasks (no "set a quit date", "identify triggers", "buy equipment", "tell a friend once", "write a plan", "research", "prepare").
- Each quest is checked off daily; user needs $targetDays days logged per habit to finish the goal.
- Habits should escalate slightly in difficulty across the list but all remain daily.
- Health-safe only.
''';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${EnvConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': EnvConfig.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You design daily repeatable habit quests for a gamified app. Every quest must be doable every single day. JSON only.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.5,
        'max_tokens': 2048,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error (${response.statusCode}): ${response.body}');
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = root['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from Groq');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final text = message?['content']?.toString() ?? '';
    if (text.isEmpty) {
      throw Exception('Empty Groq response');
    }

    final planJson = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
    return GeneratedGoalPlan.fromJson(planJson, timelineMonths);
  }

  String _extractJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```json?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return text.trim();
  }
}
