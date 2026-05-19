import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'goal_models.dart';
import 'goal_repository.dart';
import 'goal_detail_screen.dart';
import 'goal_wizard_screen.dart';
import 'section_header.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GoalRepository();

    return StreamBuilder<List<AiGoal>>(
      stream: repo.watchGoals(),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'AI GOALS', subtitle: 'LONG-TERM PROTOCOLS'),
            const SizedBox(height: 8),
            const Text(
              'AI builds daily habits you log every day. After enough days logged, claim your hunter reward.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pureBlack,
                  foregroundColor: AppColors.pureWhite,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalWizardScreen()),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('NEW AI GOAL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            if (goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  border: Border.all(color: AppColors.pureBlack, width: 2),
                ),
                child: const Text(
                  'NO ACTIVE PROTOCOLS.\nTell the System what you want to achieve.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
                ),
              )
            else
              ...goals.map((g) => _GoalCard(goal: g)),
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final AiGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.overallProgress;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goal.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: goal.isCompleted ? AppColors.mutedGreen : AppColors.pureWhite,
          border: Border.all(
            color: goal.isCompleted ? AppColors.darkGreen : AppColors.pureBlack,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.pureBlack,
                  child: Text(
                    goal.isCompleted ? 'DONE' : '${goal.timelineMonths}M',
                    style: const TextStyle(color: AppColors.neonGreen, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: AppColors.darkGreen,
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.minDaysLogged}/${goal.targetDays} DAYS • ${goal.totalQuests} HABITS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+${goal.rewardPoints} PTS ON COMPLETE',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
