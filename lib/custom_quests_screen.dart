import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'custom_quest.dart';
import 'app_colors.dart';

class CustomQuestsScreen extends StatefulWidget {
  const CustomQuestsScreen({super.key});

  @override
  State<CustomQuestsScreen> createState() => _CustomQuestsScreenState();
}

class _CustomQuestsScreenState extends State<CustomQuestsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  DatabaseReference? _customQuestsRef;
  StreamSubscription<DatabaseEvent>? _sub;
  List<CustomQuest> _quests = [];
  bool _isSaving = false;

  String _iconKey = 'fitness_center';
  String _primaryStat = 'STRENGTH';
  String _secondaryStat = 'STAMINA';
  int _primaryAmount = 10;
  int _secondaryAmount = 5;
  bool _useSecondaryReward = true;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _customQuestsRef = FirebaseDatabase.instance.ref('users/$_uid/customQuests');
      _sub = _customQuestsRef!.onValue.listen((event) {
        if (!mounted) return;
        final value = event.snapshot.value;
        if (value is Map) {
          setState(() {
            _quests = value.entries
                .map((e) => CustomQuest.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title));
          });
        } else {
          setState(() => _quests = []);
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveQuest() async {
    if (_customQuestsRef == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final tags = <String>[
      buildRewardTag(_primaryAmount, _primaryStat),
      if (_useSecondaryReward) buildRewardTag(_secondaryAmount, _secondaryStat),
    ];

    final quest = CustomQuest(
      id: '',
      title: _titleController.text.trim().toUpperCase(),
      desc: _descController.text.trim(),
      tags: tags,
      iconKey: _iconKey,
    );

    try {
      await _customQuestsRef!.push().set(quest.toMap());
      if (!mounted) return;
      _titleController.clear();
      _descController.clear();
      setState(() {
        _iconKey = 'fitness_center';
        _primaryStat = 'STRENGTH';
        _secondaryStat = 'STAMINA';
        _primaryAmount = 10;
        _secondaryAmount = 5;
        _useSecondaryReward = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom quest deployed'), backgroundColor: AppColors.darkGreen),
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

  Future<void> _deleteQuest(CustomQuest quest) async {
    if (_customQuestsRef == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE QUEST?'),
        content: Text('Remove "${quest.title}" from your protocol?'),
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

    try {
      await _customQuestsRef!.child(quest.id).remove();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.deepRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.pureBlack,
        elevation: 0,
        title: const Text('CUSTOM QUESTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: Divider(height: 3, thickness: 3, color: AppColors.pureBlack),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFormCard(),
          const SizedBox(height: 32),
          const Text('YOUR PROTOCOLS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 12),
          if (_quests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                border: Border.all(color: AppColors.pureBlack, width: 2),
              ),
              child: const Text('No custom quests yet. Create one above.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._quests.map(_buildQuestTile),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 3),
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEW QUEST', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration('QUEST TITLE'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: _inputDecoration('DESCRIPTION (OPTIONAL)'),
            ),
            const SizedBox(height: 16),
            const Text('ICON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: questIconOptions.entries.map((entry) {
                final selected = _iconKey == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.neonGreen : AppColors.pureWhite,
                      border: Border.all(color: AppColors.pureBlack, width: 2),
                    ),
                    child: Icon(entry.value),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('REWARDS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _rewardRow(
              stat: _primaryStat,
              amount: _primaryAmount,
              onStatChanged: (v) => setState(() => _primaryStat = v!),
              onAmountChanged: (v) => setState(() => _primaryAmount = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _useSecondaryReward,
                    onChanged: (v) => setState(() => _useSecondaryReward = v ?? false),
                    side: const BorderSide(color: AppColors.pureBlack, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('SECONDARY REWARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            if (_useSecondaryReward) ...[
              const SizedBox(height: 8),
              _rewardRow(
                stat: _secondaryStat,
                amount: _secondaryAmount,
                onStatChanged: (v) => setState(() => _secondaryStat = v!),
                onAmountChanged: (v) => setState(() => _secondaryAmount = v),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pureBlack,
                  foregroundColor: AppColors.pureWhite,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: _isSaving ? null : _saveQuest,
                child: Text(
                  _isSaving ? 'DEPLOYING...' : 'CREATE QUEST',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardRow({
    required String stat,
    required int amount,
    required ValueChanged<String?> onStatChanged,
    required ValueChanged<int> onAmountChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: _inputDecoration('STAT'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: stat,
                items: questStatOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: onStatChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('+$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Slider(
                value: amount.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '+$amount',
                onChanged: (v) => onAmountChanged(v.round()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestTile(CustomQuest quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)),
          child: quest.icon,
        ),
        title: Text(quest.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quest.desc.isNotEmpty) Text(quest.desc, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: quest.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.mutedGreen,
                        child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ))
                  .toList(),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.deepRed),
          onPressed: () => _deleteQuest(quest),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neonGreen, width: 2),
      ),
    );
  }
}
