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
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProfileScreen(),
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
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            const Icon(Icons.settings, color: AppColors.pureBlack),
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
          children: const [
            StatBox(title: 'STRENGTH', value: '142'),
            StatBox(title: 'AGILITY', value: '89'),
            StatBox(title: 'INTELLECT', value: '205'),
            StatBox(title: 'VITALITY', value: '118'),
          ],
        ),
        const SizedBox(height: 32),
        const SectionHeader(title: 'DAILY QUESTS', subtitle: '03 / 08 REW. OBTAINED'),
        const SizedBox(height: 16),
        const QuestItem(title: 'DRINK 2L WATER', desc: 'Maintain biological peak performance', tags: ['+10 STAMINA', '+5 FOCUS']),
        const QuestItem(title: 'GO TO THE GYM', desc: 'Physical vessel strengthening required', tags: ['+25 STRENGTH', '+15 VITALITY'], isIncomplete: true),
        // Active Buff representation
        Container(
          height: 150,
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            border: Border.all(color: AppColors.pureBlack, width: 2),
            image: const DecorationImage(
              image: NetworkImage('https://dummyimage.com/600x400/000/fff&text=HoloUI'),
              fit: BoxFit.cover,
              opacity: 0.5,
            )
          ),
          child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(color: AppColors.pureBlack, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: const Text('ACTIVE BUFF', style: TextStyle(color: AppColors.pureWhite, fontSize: 10, fontWeight: FontWeight.bold))),
                 const Spacer(),
                 const Text('THE MONARCH\'S FOCUS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.pureBlack)),
                 const SizedBox(height: 8),
                 const Text('2H 14M REMAINING', style: TextStyle(fontWeight: FontWeight.bold)),
               ],
             )
          )
        ).animate().fade().slideY(begin: 0.1, end: 0)
      ],
    );
  }
}

// ================= Profile Screen =================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
               const Text('Faizan Ahmad', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
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
  
  const QuestItem({super.key, required this.title, required this.desc, required this.tags, this.isIncomplete = false});

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
                    child: const Icon(Icons.water_drop),
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
