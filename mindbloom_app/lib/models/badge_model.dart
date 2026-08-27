enum BadgeCategory {
  streak,
  mindfulness,
  hydration,
  gratitude,
  habits,
}

class MindbloomBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final BadgeCategory category;
  final int requiredCount;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const MindbloomBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredCount,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  MindbloomBadge copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return MindbloomBadge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      category: category,
      requiredCount: requiredCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'category': category.name,
        'requiredCount': requiredCount,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory MindbloomBadge.fromJson(Map<String, dynamic> json) {
    return MindbloomBadge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: BadgeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => BadgeCategory.mindfulness,
      ),
      requiredCount: json['requiredCount'] as int? ?? 1,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }
}
