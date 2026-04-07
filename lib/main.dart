import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const HabitQuestApp());
}

class AppColors {
  static const Color background = Color(0xFFF0F0F0);
  static const Color pureWhite = Colors.white;
  static const Color pureBlack = Colors.black;
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color mutedGreen = Color(0xFFD4E5DB);
  static const Color darkGreen = Color(0xFF008000);
  static const Color deepRed = Color(0xFF8B0000);
  static const Color mutedRed = Color(0xFFE5D4D4);
  static const Color softBlue = Color(0xFFD4E0E5);
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
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  final List<String> validUsernames = ['faizan', 'admin', 'sharjeel','wannabenomi'];
  final List<String> validPasswords = ['shadow123', 'admin', 'sharj','nomi'];
  final List<String> validFullNames = ['Faizan Ahmad', 'Admin', 'Sharjeel Farsheed','Nouman Ahmed'];

  bool isLoginMode = true;

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (isLoginMode) {
      int loggedInIndex = -1;
      for (int i = 0; i < validUsernames.length; i++) {
        if (validUsernames[i] == username && validPasswords[i] == password) {
          loggedInIndex = i;
          break;
        }
      }

      if (loggedInIndex != -1) {
        String userFullName = validFullNames.length > loggedInIndex ? validFullNames[loggedInIndex] : username;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainLayout(fullName: userFullName)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Failed.....Please Try Again'),
            backgroundColor: AppColors.deepRed,
          ),
        );
      }
    } else {
      if (username.isNotEmpty && password.isNotEmpty && fullName.isNotEmpty) {
        validUsernames.add(username);
        validPasswords.add(password);
        validFullNames.add(fullName);
        setState(() {
          isLoginMode = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Please login.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
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
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'USERNAME',
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
                        _usernameController.clear();
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

  List<Widget> get _screens => [
    const DashboardScreen(),
    ProfileScreen(fullName: widget.fullName),
    const Center(child: Text('RANKING')),
    const Center(child: Text('SETTINGS')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
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

class _DashboardScreenState extends State<DashboardScreen> {
  final Map<String, int> stats = {
    'STRENGTH': 142,
    'AGILITY': 89,
    'INTELLECT': 205,
    'VITALITY': 118,
  };

  void _applyRewards(List<String> tags) {
    setState(() {
      for (var tag in tags) {
        final parts = tag.split(' ');
        if (parts.length >= 2 && parts[0].startsWith('+')) {
          final val = int.tryParse(parts[0].substring(1)) ?? 0;
          final statName = parts[1].toUpperCase();
          if (stats.containsKey(statName)) {
            stats[statName] = (stats[statName] ?? 0) + val;
          } else {
            stats[statName] = val;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Icon(Icons.settings, color: AppColors.pureBlack),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Icon(Icons.logout, color: AppColors.deepRed),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'SYSTEM SYNCHRONIZATION',
          style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const Text(
          'DAY 30 / 90',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 16),
        LinearPercentIndicator(
          lineHeight: 14.0,
          percent: 0.333,
          backgroundColor: Colors.grey[300],
          progressColor: AppColors.pureBlack,
          trailing: const Text(' 33.3% COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 32),
        const SectionHeader(title: 'CORE STATS', subtitle: 'LEVEL 32'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            StatBox(title: 'STRENGTH', value: '${stats['STRENGTH']}'),
            StatBox(title: 'AGILITY', value: '${stats['AGILITY']}'),
            StatBox(title: 'INTELLECT', value: '${stats['INTELLECT']}'),
            StatBox(title: 'VITALITY', value: '${stats['VITALITY']}'),
          ],
        ),
        const SizedBox(height: 32),
        const SectionHeader(title: 'DAILY QUESTS', subtitle: '03 / 08 REW. OBTAINED'),
        const SizedBox(height: 16),
        QuestItem(
          title: 'DRINK 2L WATER', 
          desc: 'Maintain biological peak performance', 
          tags: const ['+10 STAMINA', '+5 FOCUS'],
          isIncomplete: true,
          icon: const Icon(Icons.water_drop),
          onComplete: () => _applyRewards(['+10 STAMINA', '+5 FOCUS']),
        ),
        QuestItem(
          title: 'GO TO THE GYM', 
          desc: 'Physical vessel strengthening required', 
          tags: const ['+25 STRENGTH', '+15 VITALITY'], 
          isIncomplete: true,
          icon: const Icon(Icons.fitness_center),
          onComplete: () => _applyRewards(['+25 STRENGTH', '+15 VITALITY']),
        ),
        QuestItem(
          title: 'READ 10 PAGES', 
          desc: 'Mental expansion protocol', 
          tags: const ['+15 WISDOM', '+10 INTELLECT'], 
          isIncomplete: true,
          icon: const Icon(Icons.menu_book),
          onComplete: () => _applyRewards(['+15 WISDOM', '+10 INTELLECT']),
        ),
        QuestItem(
          title: 'MEDITATE', 
          desc: 'Aura and mind regeneration', 
          tags: const ['+20 MANA', '+15 AGILITY'],
          isIncomplete: true,
          icon: const Icon(Icons.self_improvement),
          onComplete: () => _applyRewards(['+20 MANA', '+15 AGILITY']),
        ),
      ],
    );
  }
}

// ================= Profile Screen =================
class ProfileScreen extends StatelessWidget {
  final String fullName;
  const ProfileScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LVL 14 • SHADOW MONARCH', style: TextStyle(fontWeight: FontWeight.w900)),
            Icon(Icons.military_tech),
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
               Container(color: AppColors.pureBlack, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: const Text('S-RANK HUNTER IDENTIFIED', style: TextStyle(color: AppColors.pureWhite, fontSize: 10, fontWeight: FontWeight.bold))),
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
                   children: const [
                     Text('OVERALL RATING', style: TextStyle(color: AppColors.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                     Text('Aggregate performance top 0.1%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 )
               ),
               Column(
                 children: const [
                   Text('84', style: TextStyle(color: AppColors.pureWhite, fontSize: 36, fontWeight: FontWeight.bold)),
                   Text('+41 GROWTH', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                 ],
               )
            ],
          )
        ),
        const SizedBox(height: 24),
        const ProfileStatBar(title: 'STRENGTH', value: '78', growth: '+12', percent: 0.78, color: AppColors.deepRed),
        const SizedBox(height: 12),
        const ProfileStatBar(title: 'WISDOM', value: '92', growth: '+04', percent: 0.92, color: AppColors.darkGreen),
        const SizedBox(height: 12),
        const ProfileStatBar(title: 'FOCUS', value: '65', growth: '+22', percent: 0.65, color: Colors.blue),
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
  final bool isIncomplete;
  final Icon icon;
  final VoidCallback? onComplete;
  
  const QuestItem({super.key, required this.title, required this.desc, required this.tags, this.isIncomplete = false, required this.icon, this.onComplete});

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
    isCompleted = !widget.isIncomplete;
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
                        color: widget.isIncomplete ? AppColors.mutedRed : AppColors.mutedGreen,
                        child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isIncomplete ? AppColors.deepRed : AppColors.darkGreen)),
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
                  if (widget.isIncomplete)
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

  const ProfileStatBar({super.key, required this.title, required this.value, required this.growth, required this.percent, required this.color});

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
               Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColors.pureBlack, width: 2)), child: const Icon(Icons.fitness_center)),
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
