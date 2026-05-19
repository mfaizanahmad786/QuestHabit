import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'env_config.dart';
import 'groq_goal_service.dart';
import 'goal_models.dart';
import 'goal_repository.dart';
import 'goal_detail_screen.dart';

class GoalWizardScreen extends StatefulWidget {
  const GoalWizardScreen({super.key});

  @override
  State<GoalWizardScreen> createState() => _GoalWizardScreenState();
}

class _GoalWizardScreenState extends State<GoalWizardScreen> {
  final _intentController = TextEditingController();
  final _ai = GroqGoalService();
  final _repo = GoalRepository();

  int _timelineMonths = 2;
  bool _isGenerating = false;
  bool _isSaving = false;
  GeneratedGoalPlan? _plan;
  String? _error;

  @override
  void dispose() {
    _intentController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final intent = _intentController.text.trim();
    if (intent.isEmpty) {
      setState(() => _error = 'Describe what you want to achieve');
      return;
    }
    if (!EnvConfig.hasGroqKey) {
      setState(() => _error = 'Add GROQ_API_KEY to your .env file');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _plan = null;
    });

    try {
      final result = await _ai.generateGoalPlan(
        userIntent: intent,
        timelineMonths: _timelineMonths,
      );
      if (!mounted) return;
      setState(() => _plan = result.plan);
      if (result.notice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.notice!),
            backgroundColor: result.usedOfflineFallback ? Colors.orange : AppColors.darkGreen,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _deploy() async {
    if (_plan == null) return;

    setState(() => _isSaving = true);
    try {
      final goalId = await _repo.saveGoal(
        plan: _plan!,
        userIntent: _intentController.text.trim(),
        timelineMonths: _timelineMonths,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goalId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.deepRed),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.pureBlack,
        elevation: 0,
        title: const Text('NEW AI GOAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: Divider(height: 3, thickness: 3, color: AppColors.pureBlack),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WHAT DO YOU WANT TO ACHIEVE?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: _intentController,
                  maxLines: 3,
                  decoration: _input('e.g. Quit smoking, quit sugar, run 5K...'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TIMELINE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3].map((months) {
                    final selected = _timelineMonths == months;
                    return ChoiceChip(
                      label: Text('$months MONTH${months > 1 ? 'S' : ''}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _timelineMonths = months),
                      selectedColor: AppColors.neonGreen,
                      side: const BorderSide(color: AppColors.pureBlack, width: 2),
                    );
                  }).toList(),
                ),
              ],
            ),
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
              onPressed: _isGenerating ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'GENERATING PROTOCOL...' : 'ASK THE SYSTEM',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.deepRed, fontSize: 11)),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 24),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_plan!.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(_plan!.summary, style: const TextStyle(fontSize: 12, height: 1.4)),
                  const SizedBox(height: 16),
                  const Text('COMPLETION REWARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._plan!.rewardStats.entries
                          .where((e) => e.value > 0)
                          .map(
                            (e) => _tag('+${e.value} ${e.key}'),
                          ),
                      _tag('+${_plan!.rewardPoints} PTS'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_plan!.quests.length} DAILY HABITS • ${_plan!.targetDays} DAYS EACH',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  ..._plan!.quests.take(5).map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• ${q.title}', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                  if (_plan!.quests.length > 5)
                    Text('... +${_plan!.quests.length - 5} more', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: AppColors.pureWhite,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: _isSaving ? null : _deploy,
                child: Text(
                  _isSaving ? 'DEPLOYING...' : 'DEPLOY GOAL',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: AppColors.mutedGreen,
      child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.pureBlack, width: 2)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.pureBlack, width: 2)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonGreen, width: 2)),
      );
}
