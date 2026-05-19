import 'package:flutter/material.dart';

const List<String> questStatOptions = ['STRENGTH', 'WISDOM', 'VITALITY', 'STAMINA'];

const Map<String, IconData> questIconOptions = {
  'flag': Icons.flag,
  'fitness_center': Icons.fitness_center,
  'water_drop': Icons.water_drop,
  'menu_book': Icons.menu_book,
  'self_improvement': Icons.self_improvement,
  'directions_walk': Icons.directions_walk,
  'bedtime': Icons.bedtime,
  'restaurant': Icons.restaurant,
  'code': Icons.code,
  'music_note': Icons.music_note,
  'cleaning_services': Icons.cleaning_services,
};

class CustomQuest {
  final String id;
  final String title;
  final String desc;
  final List<String> tags;
  final String iconKey;

  const CustomQuest({
    required this.id,
    required this.title,
    required this.desc,
    required this.tags,
    required this.iconKey,
  });

  String get completionId => 'custom_$id';

  Icon get icon => Icon(questIconOptions[iconKey] ?? Icons.flag);

  factory CustomQuest.fromMap(String id, Map<dynamic, dynamic> data) {
    final tagsRaw = data['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        tags.add(t.toString());
      }
    }
    return CustomQuest(
      id: id,
      title: data['title']?.toString() ?? 'UNNAMED QUEST',
      desc: data['desc']?.toString() ?? '',
      tags: tags,
      iconKey: data['icon']?.toString() ?? 'flag',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'desc': desc,
        'tags': tags,
        'icon': iconKey,
      };
}

List<CustomQuest> parseCustomQuests(Map<dynamic, dynamic>? userData) {
  if (userData == null) return [];
  final raw = userData['customQuests'];
  if (raw is! Map) return [];

  final quests = <CustomQuest>[];
  raw.forEach((key, value) {
    if (value is Map) {
      quests.add(CustomQuest.fromMap(key.toString(), value));
    }
  });
  quests.sort((a, b) => a.title.compareTo(b.title));
  return quests;
}

String buildRewardTag(int amount, String stat) => '+$amount ${stat.toUpperCase()}';
