import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'goal_models.dart';
import 'goal_repository.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _repo = GoalRepository();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _toggleQuest(AiGoal goal, GoalQuest quest) async {
    if (goal.isCompleted) return;
    final logToday = !quest.loggedToday;
    await _repo.logQuestToday(goalId: goal.id, questId: quest.id, logToday: logToday);
  }

  Future<void> _claimReward(AiGoal goal) async {
    try {
      await _repo.claimGoalCompletion(goal.id);
      _confettiController.play();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal complete! Rewards applied to your hunter stats.'),
          backgroundColor: AppColors.darkGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.deepRed),
      );
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE GOAL?'),
        content: const Text('This removes the goal and all its quests.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteGoal(widget.goalId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AiGoal?>(
      stream: _repo.watchGoal(widget.goalId),
      builder: (context, snapshot) {
        final goal = snapshot.data;
        if (goal == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.pureBlack)),
          );
        }

        final canClaim = goal.allQuestsDone && goal.isActive;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.pureWhite,
            foregroundColor: AppColors.pureBlack,
            elevation: 0,
            title: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            actions: [
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.deepRed), onPressed: _deleteGoal),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(3),
              child: Divider(height: 3, thickness: 3, color: AppColors.pureBlack),
            ),
          ),
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack,
                      border: Border.all(color: AppColors.neonGreen, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.isCompleted ? 'PROTOCOL COMPLETE' : 'ACTIVE PROTOCOL',
                          style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(goal.summary, style: const TextStyle(color: AppColors.pureWhite, fontSize: 12, height: 1.4)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: goal.overallProgress,
                          backgroundColor: Colors.grey[700],
                          color: AppColors.neonGreen,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LOG DAILY • ${goal.targetDays} DAYS PER HABIT • ${goal.timelineMonths} MONTH PLAN',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('COMPLETION REWARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...goal.rewardStats.entries
                          .where((e) => e.value > 0)
                          .map((e) => _rewardChip('+${e.value} ${e.key}')),
                      _rewardChip('+${goal.rewardPoints} PTS'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check off each habit once per day. Daily quests do not change stats until you claim.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text('DAILY HABITS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  const SizedBox(height: 12),
                  ...goal.quests.map((q) => _GoalQuestTile(
                        quest: q,
                        targetDays: goal.targetDays,
                        locked: goal.isCompleted,
                        onToggle: () => _toggleQuest(goal, q),
                      )),
                  if (canClaim) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          foregroundColor: AppColors.pureWhite,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () => _claimReward(goal),
                        child: const Text('CLAIM HUNTER REWARD', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [AppColors.neonGreen, AppColors.pureBlack, Colors.white],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rewardChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.mutedGreen,
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _GoalQuestTile extends StatelessWidget {
  final GoalQuest quest;
  final int targetDays;
  final bool locked;
  final VoidCallback onToggle;

  const _GoalQuestTile({
    required this.quest,
    required this.targetDays,
    required this.locked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final loggedToday = quest.loggedToday;
    final done = quest.daysCompleted >= targetDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: done ? AppColors.mutedGreen : (loggedToday ? AppColors.mutedGreen : AppColors.pureWhite),
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppColors.pureBlack,
                      child: Text(
                        done ? 'COMPLETE' : (loggedToday ? 'LOGGED TODAY' : 'DAILY'),
                        style: const TextStyle(color: AppColors.neonGreen, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(quest.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                if (quest.desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(quest.desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
                const SizedBox(height: 8),
                Text(
                  '${quest.daysCompleted}/$targetDays days logged',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: done ? AppColors.darkGreen : AppColors.pureBlack,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: locked || done ? null : onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)),
              child: loggedToday || done ? const Icon(Icons.check, size: 20) : null,
            ),
          ),
        ],
      ),
    );
  }
}
