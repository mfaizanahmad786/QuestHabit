import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'app_colors.dart';
import 'ranking_logic.dart';
import 'custom_quests_screen.dart';

Map<String, dynamic> _defaultHunterStats() => {
      'STRENGTH': 10,
      'WISDOM': 10,
      'VITALITY': 10,
      'STAMINA': 10,
    };

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const SettingsScreen({super.key, required this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  DatabaseReference? _userRef;
  StreamSubscription<DatabaseEvent>? _sub;
  Map<dynamic, dynamic> _userData = {};

  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    syncHunterNameToDatabase();
    if (_uid != null) {
      _userRef = FirebaseDatabase.instance.ref('users/$_uid');
      _sub = _userRef!.onValue.listen((event) {
        if (event.snapshot.value != null && mounted) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _userData = data;
            _notificationsEnabled = _readNotifications(data);
            final name = resolveHunterName(
              data,
              fallback: hunterNameFromAuth(FirebaseAuth.instance.currentUser),
            );
            if (_nameController.text != name) {
              _nameController.text = name;
            }
          });
        }
      });
    }
  }

  bool _readNotifications(Map<dynamic, dynamic> data) {
    final settings = data['settings'];
    if (settings is Map && settings['questReminders'] != null) {
      return settings['questReminders'] == true;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  int get _totalDays => _asInt(_userData['totalDays'], 90);
  int get _currentDay => _asInt(_userData['currentDay'], 1);

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _userRef == null) return;

    setState(() => _isSavingName = true);
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      await _userRef!.update({'name': name});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hunter name updated'), backgroundColor: AppColors.darkGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e'), backgroundColor: AppColors.deepRed),
      );
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _updateProtocolDays(int days) async {
    await _userRef?.update({'totalDays': days});
  }

  Future<void> _advanceProtocolDay() async {
    final next = (_currentDay + 1).clamp(1, _totalDays);
    await _userRef?.update({'currentDay': next});
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _userRef?.update({'settings/questReminders': value});
  }

  Future<void> _resetDailyQuests() async {
    final confirmed = await _confirm(
      'RESET DAILY QUESTS?',
      'All built-in and custom quests will be marked incomplete. Stats and points are kept.',
    );
    if (confirmed != true) return;
    await _userRef?.update({'completedQuests': []});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily quests reset'), backgroundColor: AppColors.darkGreen),
    );
  }

  Future<void> _resetAllProgress() async {
    final confirmed = await _confirm(
      'RESET ALL PROGRESS?',
      'This resets stats, points, rank, level, overall rating, and completed quests. Custom quests are kept.',
      destructive: true,
    );
    if (confirmed != true) return;
    await _userRef?.update({
      'stats': _defaultHunterStats(),
      'points': 0,
      'level': 1,
      'rank': 'E',
      'completedQuests': [],
      'overallRating': 10,
      'currentDay': 1,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset to day 1'), backgroundColor: AppColors.darkGreen),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CHANGE PASSWORD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'CURRENT PASSWORD'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'NEW PASSWORD'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('UPDATE')),
        ],
      ),
    );

    if (confirmed != true) {
      currentController.dispose();
      newController.dispose();
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.darkGreen),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Password update failed'), backgroundColor: AppColors.deepRed),
      );
    } finally {
      currentController.dispose();
      newController.dispose();
    }
  }

  Future<bool?> _confirm(String title, String message, {bool destructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'CONFIRM',
              style: TextStyle(color: destructive ? AppColors.deepRed : AppColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('SYSTEM SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'CONFIGURE YOUR HUNTER PROTOCOL',
          style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('HUNTER PROFILE'),
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDecoration('HUNTER NAME'),
              ),
              const SizedBox(height: 8),
              Text('EMAIL: $email', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: _isSavingName ? null : _saveName,
                  child: Text(_isSavingName ? 'SAVING...' : 'SAVE NAME'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('SOVEREIGN PROTOCOL'),
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PROTOCOL LENGTH', style: _labelStyle()),
                  Text('$_totalDays DAYS', style: _valueStyle()),
                ],
              ),
              Slider(
                value: _totalDays.toDouble(),
                min: 30,
                max: 180,
                divisions: 5,
                label: '$_totalDays',
                onChanged: (v) => _updateProtocolDays(v.round()),
              ),
              const Divider(height: 24, color: AppColors.pureBlack),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT DAY', style: _labelStyle()),
                      Text('DAY $_currentDay / $_totalDays', style: _valueStyle()),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pureBlack,
                      side: const BorderSide(color: AppColors.pureBlack, width: 2),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _currentDay >= _totalDays ? null : _advanceProtocolDay,
                    child: const Text('ADVANCE DAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('QUESTS'),
        _SettingsTile(
          title: 'MANAGE CUSTOM QUESTS',
          subtitle: 'Create, view, or delete your own quests',
          icon: Icons.add_task,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomQuestsScreen()),
            );
          },
        ),
        _SettingsCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('QUEST REMINDERS', style: _labelStyle()),
            subtitle: const Text('Daily nudges to complete your protocol', style: TextStyle(fontSize: 11)),
            value: _notificationsEnabled,
            activeThumbColor: AppColors.neonGreen,
            onChanged: _setNotifications,
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('DATA'),
        _SettingsTile(
          title: 'RESET DAILY QUESTS',
          subtitle: 'Mark all quests incomplete for a fresh day',
          icon: Icons.refresh,
          onTap: _resetDailyQuests,
        ),
        _SettingsTile(
          title: 'RESET ALL PROGRESS',
          subtitle: 'Wipe stats, points, rank, and quest history',
          icon: Icons.delete_forever,
          titleColor: AppColors.deepRed,
          onTap: _resetAllProgress,
        ),
        const SizedBox(height: 24),
        const _SectionLabel('SECURITY'),
        _SettingsTile(
          title: 'CHANGE PASSWORD',
          subtitle: 'Update your system access credentials',
          icon: Icons.lock_outline,
          onTap: _showChangePasswordDialog,
        ),
        _SettingsTile(
          title: 'SIGN OUT',
          subtitle: 'End current hunter session',
          icon: Icons.logout,
          titleColor: AppColors.deepRed,
          onTap: widget.onSignOut,
        ),
        const SizedBox(height: 24),
        const _SectionLabel('ABOUT'),
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HABIT QUEST', style: _valueStyle()),
              const SizedBox(height: 4),
              const Text('Sovereign Protocol v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text(
                'Gamified habit tracking for hunters leveling up in real life.',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.pureBlack, width: 2)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.pureBlack, width: 2)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonGreen, width: 2)),
      );

  TextStyle _labelStyle() => const TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
  TextStyle _valueStyle() => const TextStyle(fontWeight: FontWeight.w900, fontSize: 16);

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.pureWhite,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      );
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.pureBlack, width: 3)),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)),
          child: Icon(icon, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: titleColor ?? AppColors.pureBlack),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
