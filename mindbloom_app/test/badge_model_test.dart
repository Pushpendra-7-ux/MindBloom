import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/badge_model.dart';

void main() {
  group('MindbloomBadge Model - Unit Tests', () {
    test('instantiates with default values', () {
      const badge = MindbloomBadge(
        id: 'test_1',
        title: 'Test Badge',
        description: 'Test Description',
        icon: '🏆',
        category: BadgeCategory.streak,
        requiredCount: 5,
      );

      expect(badge.id, equals('test_1'));
      expect(badge.title, equals('Test Badge'));
      expect(badge.category, equals(BadgeCategory.streak));
      expect(badge.isUnlocked, isFalse);
      expect(badge.unlockedAt, isNull);
    });

    test('copyWith updates unlock status and timestamp', () {
      const badge = MindbloomBadge(
        id: 'test_1',
        title: 'Test Badge',
        description: 'Test Description',
        icon: '🏆',
        category: BadgeCategory.gratitude,
        requiredCount: 3,
      );

      final now = DateTime.now();
      final updated = badge.copyWith(isUnlocked: true, unlockedAt: now);

      expect(updated.isUnlocked, isTrue);
      expect(updated.unlockedAt, equals(now));
      expect(updated.title, equals('Test Badge'));
    });

    test('toJson and fromJson serialization works symmetrically', () {
      final now = DateTime.now();
      final badge = MindbloomBadge(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Maintained a 7-day wellness streak',
        icon: '⚡',
        category: BadgeCategory.streak,
        requiredCount: 7,
        isUnlocked: true,
        unlockedAt: now,
      );

      final json = badge.toJson();
      expect(json['id'], equals('streak_7'));
      expect(json['category'], equals('streak'));
      expect(json['isUnlocked'], isTrue);

      final decoded = MindbloomBadge.fromJson(json);
      expect(decoded.id, equals(badge.id));
      expect(decoded.title, equals(badge.title));
      expect(decoded.category, equals(badge.category));
      expect(decoded.isUnlocked, isTrue);
      expect(decoded.unlockedAt?.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });
}
