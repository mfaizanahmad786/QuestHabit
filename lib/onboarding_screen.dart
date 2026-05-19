import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

const String _onboardingCompleteKey = 'onboarding_complete';

Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingCompleteKey, true);
}

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _slides = [
  OnboardingSlide(
    icon: Icons.task_alt,
    title: 'COMPLETE DAILY QUESTS',
    body:
        'Finish built-in and custom quests each day. Every completion boosts your stats and earns system points.',
  ),
  OnboardingSlide(
    icon: Icons.person,
    title: 'LEVEL UP YOUR HUNTER',
    body:
        'Track Strength, Wisdom, Vitality, and Stamina. Watch your rank, level, and overall rating climb on the Player screen.',
  ),
  OnboardingSlide(
    icon: Icons.emoji_events,
    title: 'COMPETE & CUSTOMIZE',
    body:
        'Climb the global leaderboard, follow your 90-day Sovereign Protocol, and deploy your own custom quests.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingComplete();
    widget.onComplete();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SYSTEM BRIEFING',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('SKIP', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pureBlack)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _SlidePage(slide: _slides[index], index: index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => Container(
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: i == _currentPage ? AppColors.pureBlack : Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pureBlack,
                        foregroundColor: AppColors.pureWhite,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: _next,
                      child: Text(
                        isLast ? 'CREATE HUNTER ACCOUNT' : 'NEXT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final OnboardingSlide slide;
  final int index;

  const _SlidePage({required this.slide, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              border: Border.all(color: AppColors.pureBlack, width: 3),
            ),
            child: Icon(slide.icon, size: 48, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 8),
          Text(
            '0${index + 1}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, height: 1.2),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              border: Border.all(color: AppColors.pureBlack, width: 2),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
