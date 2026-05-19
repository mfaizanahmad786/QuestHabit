import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_colors.dart';
import 'section_header.dart';
import 'ranking_logic.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    syncHunterNameToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.pureBlack));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'DATABASE ERROR\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.deepRed, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        Map<dynamic, dynamic>? usersData;
        if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
          usersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        }

        final authName = hunterNameFromAuth(FirebaseAuth.instance.currentUser);
        final leaderboard = buildLeaderboard(
          usersData,
          currentUid: currentUid,
          currentUserName: authName,
        );
        final myPosition = positionForUser(leaderboard, currentUid);
        final me = hunterForUser(leaderboard, currentUid);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              title: 'GLOBAL RANKING',
              subtitle: '${leaderboard.length} HUNTERS',
            ),
            const SizedBox(height: 16),
            if (me != null && myPosition != null) ...[
              _YourRankCard(hunter: me, position: myPosition, total: leaderboard.length),
              const SizedBox(height: 16),
            ],
            if (leaderboard.length >= 3) ...[
              _PodiumRow(
                first: leaderboard[0],
                second: leaderboard[1],
                third: leaderboard[2],
                currentUid: currentUid,
              ),
              const SizedBox(height: 24),
            ],
            if (leaderboard.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  border: Border.all(color: AppColors.pureBlack, width: 2),
                ),
                child: const Text(
                  'NO HUNTERS ON THE BOARD YET.\nCOMPLETE QUESTS TO CLAIM A RANK.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
                ),
              )
            else
              ...leaderboard.asMap().entries.map(
                    (entry) => _LeaderboardTile(
                      hunter: entry.value,
                      position: entry.key + 1,
                      isCurrentUser: entry.value.uid == currentUid,
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _YourRankCard extends StatelessWidget {
  final RankedHunter hunter;
  final int position;
  final int total;

  const _YourRankCard({
    required this.hunter,
    required this.position,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        border: Border.all(color: AppColors.neonGreen, width: 3),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR RANK',
                style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                '#$position',
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 40, fontWeight: FontWeight.w900),
              ),
              Text(
                rankSubtitle(position, total),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RankBadge(rank: hunter.rank, inverted: true),
              const SizedBox(height: 8),
              Text(
                '${hunter.points} PTS',
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'LVL ${hunter.level} • OVR ${hunter.overallRating}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final RankedHunter first;
  final RankedHunter second;
  final RankedHunter third;
  final String? currentUid;

  const _PodiumRow({
    required this.first,
    required this.second,
    required this.third,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSlot(hunter: second, position: 2, currentUid: currentUid, height: 88)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(hunter: first, position: 1, currentUid: currentUid, height: 110)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(hunter: third, position: 3, currentUid: currentUid, height: 72)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final RankedHunter hunter;
  final int position;
  final String? currentUid;
  final double height;

  const _PodiumSlot({
    required this.hunter,
    required this.position,
    required this.currentUid,
    required this.height,
  });

  Color get _accent {
    switch (position) {
      case 1:
        return AppColors.neonGreen;
      case 2:
        return AppColors.softBlue;
      default:
        return AppColors.mutedRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = hunter.uid == currentUid;
    return Column(
      children: [
        Text(
          hunter.name.split(' ').first.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isMe ? AppColors.darkGreen : AppColors.pureBlack,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: isMe ? AppColors.neonGreen.withValues(alpha: 0.25) : AppColors.pureWhite,
            border: Border.all(
              color: isMe ? AppColors.darkGreen : AppColors.pureBlack,
              width: isMe ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                position == 1 ? Icons.emoji_events : Icons.military_tech,
                color: _accent,
                size: position == 1 ? 28 : 22,
              ),
              const SizedBox(height: 4),
              Text(
                '#$position',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                '${hunter.points}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final RankedHunter hunter;
  final int position;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.hunter,
    required this.position,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.mutedGreen : AppColors.pureWhite,
        border: Border.all(
          color: isCurrentUser ? AppColors.darkGreen : AppColors.pureBlack,
          width: isCurrentUser ? 3 : 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$position',
              style: TextStyle(
                fontSize: position <= 3 ? 22 : 18,
                fontWeight: FontWeight.w900,
                color: position == 1 ? AppColors.darkGreen : AppColors.pureBlack,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RankBadge(rank: hunter.rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hunter.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isCurrentUser ? AppColors.darkGreen : AppColors.pureBlack,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.pureBlack,
                        child: const Text(
                          'YOU',
                          style: TextStyle(color: AppColors.neonGreen, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Text(
                  'LVL ${hunter.level} • OVR ${hunter.overallRating}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${hunter.points}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text('PTS', style: TextStyle(fontSize: 10, color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String rank;
  final bool inverted;

  const _RankBadge({required this.rank, this.inverted = false});

  Color get _rankColor {
    switch (rank.toUpperCase()) {
      case 'S':
        return AppColors.neonGreen;
      case 'A':
        return AppColors.darkGreen;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.grey;
      case 'D':
        return AppColors.pureWhite;
      default:
        return AppColors.pureBlack;
    }
  }

  Color get _invertedBackground {
    if (rank.toUpperCase() == 'D') return AppColors.pureWhite;
    return _rankColor;
  }

  Color get _invertedForeground {
    if (rank.toUpperCase() == 'D') return AppColors.pureBlack;
    return AppColors.pureWhite;
  }

  @override
  Widget build(BuildContext context) {
    if (inverted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: _invertedBackground,
        child: Text(
          '$rank-RANK',
          style: TextStyle(color: _invertedForeground, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.pureBlack,
      child: Text(
        '$rank-RANK',
        style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
