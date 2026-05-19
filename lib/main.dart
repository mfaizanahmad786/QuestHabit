import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'ranking_screen.dart';
import 'ranking_logic.dart';
import 'custom_quest.dart';
import 'custom_quests_screen.dart';
import 'settings_screen.dart';
import 'daily_reset.dart';

import 'firebase_options.dart';
import 'app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HabitQuestApp());
}

class HabitQuestApp extends StatelessWidget {
  const HabitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.robotoMonoTextTheme().apply(
          bodyColor: AppColors.pureBlack,
          displayColor: AppColors.pureBlack,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.pureBlack,
          secondary: AppColors.neonGreen,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user != null) {
          return _AuthenticatedHome(user: user);
        }

        return const LoginScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOVEREIGN PROTOCOL',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
            ),
            SizedBox(height: 8),
            Text(
              'SYNCHRONIZING HUNTER DATA...',
              style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.pureBlack),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  final User user;

  const _AuthenticatedHome({required this.user});

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  @override
  void initState() {
    super.initState();
    syncHunterNameToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(fullName: hunterNameFromAuth(widget.user));
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  bool isLoginMode = true;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLoginMode && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.deepRed),
      );
      return;
    }

    try {
      if (isLoginMode) {
        // Login Flow
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await syncHunterNameToDatabase();
        // AuthGate listens to authStateChanges and shows MainLayout automatically.
      } else {
        // Registration Flow
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        await userCredential.user?.updateDisplayName(fullName);
        
        final userRef = FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}');
        await userRef.set({
          'name': fullName,
          'level': 1,
          'points': 0,
          'rank': 'E',
          'currentDay': 1,
          'totalDays': 90,
          'stats': {
            'STRENGTH': 10,
            'WISDOM': 10,
            'VITALITY': 10,
            'STAMINA': 10,
          },
          'overallRating': _startingOverallRating,
          'lastQuestResetDate': todayDateKey(),
        });
        
        if (!mounted) return;
        setState(() {
          isLoginMode = true;
          _passwordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Please login.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication failed'),
          backgroundColor: AppColors.deepRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                border: Border.all(color: AppColors.pureBlack, width: 3),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLoginMode ? 'SYSTEM LOGIN' : 'NEW REGISTRATION',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 32),
                  if (!isLoginMode) ...[
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'FULL NAME',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.neonGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'EMAIL',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'PASSWORD',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pureBlack, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pureBlack,
                        foregroundColor: AppColors.pureWhite,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isLoginMode ? 'LOG IN' : 'REGISTER',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLoginMode = !isLoginMode;
                        _emailController.clear();
                        _passwordController.clear();
                        _fullNameController.clear();
                      });
                    },
                    child: Text(
                      isLoginMode ? 'CREATE NEW ACCOUNT' : 'RETURN TO LOGIN',
                      style: const TextStyle(color: AppColors.pureBlack, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final String fullName;
  const MainLayout({super.key, required this.fullName});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const ProfileScreen(),
    const RankingScreen(),
    SettingsScreen(onSignOut: _signOut),
  ];

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate shows LoginScreen when auth state becomes null.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.pureBlack, width: 3)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.pureWhite,
          selectedItemColor: AppColors.pureBlack,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'QUESTS'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PLAYER'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'RANK'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}

// ================= Dashboard Screen =================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

const int _maxOverallRating = 100;
const int _overallRatingPerQuest = 3;
const int _startingOverallRating = 10;

int _completedQuestCount(Map<dynamic, dynamic> userData) {
  final completed = userData['completedQuests'];
  if (completed is List) return completed.length;
  return 0;
}

int _overallRatingFromUserData(Map<dynamic, dynamic> userData) {
  if (userData.containsKey('overallRating')) {
    return _asInt(userData['overallRating']).clamp(0, _maxOverallRating);
  }
  // Legacy users: estimate from quests completed before this field existed
  return (_startingOverallRating + _completedQuestCount(userData) * _overallRatingPerQuest)
      .clamp(0, _maxOverallRating);
}

String _overallRatingSubtitle(int rating) {
  if (rating >= 95) return 'Aggregate performance top 0.1%';
  if (rating >= 80) return 'Elite hunter trajectory';
  if (rating >= 60) return 'Rising sovereign candidate';
  if (rating >= 40) return 'Steady protocol adherence';
  return 'Foundation phase — keep grinding';
}

int _getStat(Map<dynamic, dynamic> statsMap, String key) {
  if (statsMap[key] != null) return _asInt(statsMap[key]);
  // Legacy accounts may still have INTELLECT instead of WISDOM
  if (key == 'WISDOM' && statsMap['INTELLECT'] != null) {
    return _asInt(statsMap['INTELLECT']);
  }
  return 10;
}

Map<String, dynamic> _defaultStats() => {
  'STRENGTH': 10,
  'WISDOM': 10,
  'VITALITY': 10,
  'STAMINA': 10,
};

class _DashboardScreenState extends State<DashboardScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  DatabaseReference? _userRef;
  Map<dynamic, dynamic> _userData = {};
  StreamSubscription<DatabaseEvent>? _sub;
  bool _dailyResetRunning = false;
  String? _dailyResetCheckedFor;

  @override
  void initState() {
    super.initState();
    if (uid != null) {
      _userRef = FirebaseDatabase.instance.ref('users/$uid');
      _sub = _userRef!.onValue.listen((event) {
        if (event.snapshot.value != null && mounted) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() => _userData = data);
          _maybeResetQuestsForNewDay(data);
        }
      });
    }
  }

  Future<void> _maybeResetQuestsForNewDay(Map<dynamic, dynamic> data) async {
    if (_userRef == null || _dailyResetRunning) return;

    final today = todayDateKey();
    final lastReset = data['lastQuestResetDate']?.toString();
    if (lastReset == today) {
      _dailyResetCheckedFor = today;
      return;
    }
    if (_dailyResetCheckedFor == today) return;

    _dailyResetRunning = true;
    try {
      final didReset = await applyDailyQuestResetIfNeeded(userRef: _userRef!, userData: data);
      if (didReset && mounted) {
        _dailyResetCheckedFor = today;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New day — daily quests reset'),
            backgroundColor: AppColors.darkGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _dailyResetRunning = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _applyRewards(List<String> tags, String questId) async {
    try {
      if (_userRef == null) return;

      List<String> completed = [];
      if (_userData['completedQuests'] != null) {
        for (var item in _userData['completedQuests']) {
          completed.add(item.toString());
        }
      }

      if (completed.contains(questId)) return;
      completed.add(questId);

      Map<String, dynamic> currentStats = {};
      if (_userData['stats'] != null) {
        (_userData['stats'] as Map).forEach((k, v) {
          currentStats[k.toString()] = _asInt(v);
        });
      } else {
        currentStats = _defaultStats();
      }

      for (var tag in tags) {
        final parts = tag.split(' ');
        if (parts.length >= 2 && parts[0].startsWith('+')) {
          final val = int.tryParse(parts[0].substring(1)) ?? 0;
          final statName = parts[1].toUpperCase();
          currentStats[statName] = _asInt(currentStats[statName]) + val;
        }
      }

      int currentPoints = _asInt(_userData['points']);
      int newPoints = currentPoints + 150;
      int newLevel = levelFromPoints(newPoints);
      String newRank = rankTierFromPoints(newPoints);

      int newOverallRating = (_overallRatingFromUserData(_userData) + _overallRatingPerQuest)
          .clamp(0, _maxOverallRating);

      if (mounted) {
        setState(() {
          _userData = {
            ...Map<dynamic, dynamic>.from(_userData),
            'stats': currentStats,
            'points': newPoints,
            'level': newLevel,
            'rank': newRank,
            'completedQuests': completed,
            'overallRating': newOverallRating,
          };
        });
      }

      await _userRef!.update({
        'stats': currentStats,
        'points': newPoints,
        'level': newLevel,
        'rank': newRank,
        'completedQuests': completed,
        'overallRating': newOverallRating,
      });
    } catch (e) {
      debugPrint('Error updating Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsMap = _userData['stats'] != null
        ? Map<dynamic, dynamic>.from(_userData['stats'] as Map)
        : <dynamic, dynamic>{};
    int str = _getStat(statsMap, 'STRENGTH');
    int wisdom = _getStat(statsMap, 'WISDOM');
    int vit = _getStat(statsMap, 'VITALITY');
    int stamina = _getStat(statsMap, 'STAMINA');
    int level = _asInt(_userData['level'], 1);
    
    int currentDay = _userData['currentDay'] ?? 1;
    int totalDays = _userData['totalDays'] ?? 90;
    double progressPercent = totalDays > 0 ? (currentDay / totalDays).clamp(0.0, 1.0) : 0.0;
    String percentString = (progressPercent * 100).toStringAsFixed(1);
    List<dynamic> completedQuests = _userData['completedQuests'] ?? [];
    final customQuests = parseCustomQuests(_userData);
    final builtInCount = 4;
    final totalQuestCount = builtInCount + customQuests.length;
    final completedCount = completedQuests.length;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SOVEREIGN PROTOCOL',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const Icon(Icons.shield, color: AppColors.pureBlack),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'SYSTEM SYNCHRONIZATION',
          style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        Text(
          'DAY $currentDay / $totalDays',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 16),
        LinearPercentIndicator(
          lineHeight: 14.0,
          percent: progressPercent,
          backgroundColor: Colors.grey[300],
          progressColor: AppColors.pureBlack,
          trailing: Text(' $percentString% COMPLETE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 32),
        SectionHeader(title: 'CORE STATS', subtitle: 'LEVEL $level'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            StatBox(title: 'STRENGTH', value: '$str'),
            StatBox(title: 'STAMINA', value: '$stamina'),
            StatBox(title: 'WISDOM', value: '$wisdom'),
            StatBox(title: 'VITALITY', value: '$vit'),
          ],
        ),
        const SizedBox(height: 32),
        SectionHeader(
          title: 'DAILY QUESTS',
          subtitle: '$completedCount / $totalQuestCount COMPLETE',
        ),
        const SizedBox(height: 16),
        QuestItem(
          title: 'DRINK 2L WATER', 
          desc: 'Maintain biological peak performance', 
          tags: const ['+10 STAMINA', '+5 VITALITY'],
          isAlreadyCompleted: completedQuests.contains('quest_water'),
          icon: const Icon(Icons.water_drop),
          onComplete: () => _applyRewards(const ['+10 STAMINA', '+5 VITALITY'], 'quest_water'),
        ),
        QuestItem(
          title: 'GO TO THE GYM', 
          desc: 'Physical vessel strengthening required', 
          tags: const ['+25 STRENGTH', '+10 STAMINA'], 
          isAlreadyCompleted: completedQuests.contains('quest_gym'),
          icon: const Icon(Icons.fitness_center),
          onComplete: () => _applyRewards(const ['+25 STRENGTH', '+10 STAMINA'], 'quest_gym'),
        ),
        QuestItem(
          title: 'READ 10 PAGES', 
          desc: 'Mental expansion protocol', 
          tags: const ['+20 WISDOM', '+5 VITALITY'], 
          isAlreadyCompleted: completedQuests.contains('quest_read'),
          icon: const Icon(Icons.menu_book),
          onComplete: () => _applyRewards(const ['+20 WISDOM', '+5 VITALITY'], 'quest_read'),
        ),
        QuestItem(
          title: 'MEDITATE', 
          desc: 'Aura and mind regeneration', 
          tags: const ['+15 WISDOM', '+10 STAMINA'],
          isAlreadyCompleted: completedQuests.contains('quest_meditate'),
          icon: const Icon(Icons.self_improvement),
          onComplete: () => _applyRewards(const ['+15 WISDOM', '+10 STAMINA'], 'quest_meditate'),
        ),
        if (customQuests.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: 'CUSTOM QUESTS', subtitle: 'USER DEPLOYED'),
          const SizedBox(height: 16),
          ...customQuests.map(
            (q) => QuestItem(
              title: q.title,
              desc: q.desc.isEmpty ? 'Custom protocol' : q.desc,
              tags: q.tags,
              isAlreadyCompleted: completedQuests.contains(q.completionId),
              icon: q.icon,
              onComplete: () => _applyRewards(q.tags, q.completionId),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pureBlack,
              side: const BorderSide(color: AppColors.pureBlack, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomQuestsScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('MANAGE CUSTOM QUESTS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ================= Profile Screen =================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  DatabaseReference? _userRef;
  Map<dynamic, dynamic> _userData = {};
  StreamSubscription<DatabaseEvent>? _sub;

  @override
  void initState() {
    super.initState();
    syncHunterNameToDatabase();
    if (uid != null) {
      _userRef = FirebaseDatabase.instance.ref('users/$uid');
      _sub = _userRef!.onValue.listen((event) {
        if (event.snapshot.value != null && mounted) {
          setState(() {
            _userData = event.snapshot.value as Map<dynamic, dynamic>;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    String fullName = resolveHunterName(
      _userData.isNotEmpty ? _userData : {},
      fallback: hunterNameFromAuth(authUser),
    );
    int level = _userData['level'] ?? 1;
    String rank = _userData['rank'] ?? 'E';
    
    // Safely extract stats
    Map<dynamic, dynamic> statsMap = _userData['stats'] != null ? Map<dynamic, dynamic>.from(_userData['stats']) : {};
    
    int str = _getStat(statsMap, 'STRENGTH');
    int wisdom = _getStat(statsMap, 'WISDOM');
    int vit = _getStat(statsMap, 'VITALITY');
    int stamina = _getStat(statsMap, 'STAMINA');
    int overallRating = _overallRatingFromUserData(_userData);

    double strPercent = (str / 250).clamp(0.0, 1.0);
    double wisdomPercent = (wisdom / 250).clamp(0.0, 1.0);
    double vitPercent = (vit / 250).clamp(0.0, 1.0);
    double staminaPercent = (stamina / 250).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LVL $level • SHADOW MONARCH', style: const TextStyle(fontWeight: FontWeight.w900)),
            const Icon(Icons.military_tech),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            border: Border.all(color: AppColors.pureBlack, width: 3),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(color: AppColors.pureBlack, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Text('$rank-RANK HUNTER IDENTIFIED', style: const TextStyle(color: AppColors.pureWhite, fontSize: 10, fontWeight: FontWeight.bold))),
               const SizedBox(height: 8),
               Text(fullName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
               const Text('The Shadow Monarch', style: TextStyle(color: AppColors.deepRed, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
            ],
          )
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        Container(
          color: AppColors.pureBlack,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
               const Icon(Icons.star_border, color: AppColors.pureWhite, size: 40),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('OVERALL RATING', style: TextStyle(color: AppColors.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                     Text(_overallRatingSubtitle(overallRating), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 )
               ),
               Column(
                 children: [
                   Text('$overallRating', style: const TextStyle(color: AppColors.pureWhite, fontSize: 36, fontWeight: FontWeight.bold)),
                   Text('/ $_maxOverallRating', style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                 ],
               )
            ],
          )
        ),
        const SizedBox(height: 24),
        ProfileStatBar(title: 'STRENGTH', value: '$str', growth: '+${(str * 0.1).ceil()}', percent: strPercent, color: AppColors.deepRed, icon: Icons.fitness_center),
        const SizedBox(height: 12),
        ProfileStatBar(title: 'WISDOM', value: '$wisdom', growth: '+${(wisdom * 0.1).ceil()}', percent: wisdomPercent, color: AppColors.darkGreen, icon: Icons.menu_book),
        const SizedBox(height: 12),
        ProfileStatBar(title: 'VITALITY', value: '$vit', growth: '+${(vit * 0.1).ceil()}', percent: vitPercent, color: Colors.blue, icon: Icons.favorite),
        const SizedBox(height: 12),
        ProfileStatBar(title: 'STAMINA', value: '$stamina', growth: '+${(stamina * 0.1).ceil()}', percent: staminaPercent, color: Colors.orange, icon: Icons.bolt),
      ],
    );
  }
}

// ================= Common Widgets =================
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.pureBlack, width: 3)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String title;
  final String value;
  const StatBox({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          Container(height: 3, width: 40, color: AppColors.pureBlack),
        ],
      )
    );
  }
}

class QuestItem extends StatefulWidget {
  final String title;
  final String desc;
  final List<String> tags;
  final bool isAlreadyCompleted;
  final Icon icon;
  final VoidCallback? onComplete;
  
  const QuestItem({super.key, required this.title, required this.desc, required this.tags, this.isAlreadyCompleted = false, required this.icon, this.onComplete});

  @override
  State<QuestItem> createState() => _QuestItemState();
}

class _QuestItemState extends State<QuestItem> {
  late ConfettiController _controller;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 1));
    isCompleted = widget.isAlreadyCompleted;
  }

  @override
  void didUpdateWidget(covariant QuestItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlreadyCompleted != oldWidget.isAlreadyCompleted) {
      isCompleted = widget.isAlreadyCompleted;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)),
                    child: widget.icon,
                  ),
                  Row(
                    children: widget.tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: !isCompleted ? AppColors.mutedRed : AppColors.mutedGreen,
                        child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: !isCompleted ? AppColors.deepRed : AppColors.darkGreen)),
                      ),
                    )).toList(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(widget.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCompleted)
                    const Text('INCOMPLETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  else
                    Row(
                      children: [
                        Container(width: 20, height: 6, color: AppColors.darkGreen, margin: const EdgeInsets.only(right: 4)),
                        Container(width: 20, height: 6, color: AppColors.darkGreen, margin: const EdgeInsets.only(right: 4)),
                        Container(width: 20, height: 6, color: AppColors.mutedGreen),
                      ],
                    ),
                  GestureDetector(
                    onTap: () {
                      if (!isCompleted) {
                        setState(() => isCompleted = true);
                        _controller.play();
                        if (widget.onComplete != null) {
                          widget.onComplete!();
                        }
                      }
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)),
                      child: isCompleted ? const Icon(Icons.check) : null,
                    ),
                  )
                ],
              )
            ],
          ),
          ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppColors.neonGreen, AppColors.pureBlack, Colors.grey],
          ),
        ]
      )
    ).animate().slideX(begin: 0.2, end: 0);
  }
}

class ProfileStatBar extends StatelessWidget {
  final String title;
  final String value;
  final String growth;
  final double percent;
  final Color color;
  final IconData icon;

  const ProfileStatBar({
    super.key,
    required this.title,
    required this.value,
    required this.growth,
    required this.percent,
    required this.color,
    this.icon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.pureBlack, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)), child: Icon(icon)),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                   Text(growth, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                 ],
               )
             ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percent,
            backgroundColor: Colors.grey[300],
            progressColor: color,
            padding: EdgeInsets.zero,
          ),
        ],
      )
    );
  }
}
