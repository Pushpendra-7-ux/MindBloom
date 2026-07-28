import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/tips_provider.dart';
import 'package:mindbloom_app/config/wellness_tips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TipsNotifier - Daily Wellness Tips Unit Tests', () {
    test('initial state has deterministic daily tip and is not loading after init', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(tipsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(tipsProvider);
      expect(state.isLoading, isFalse);
      expect(state.currentTip, isNotNull);
      expect(state.currentTip['text'], isNotEmpty);
      expect(state.currentTip['category'], isNotEmpty);
    });

    test('nextTip advances through tips circularly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(tipsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final initialIndex = container.read(tipsProvider).currentIndex;
      final initialTipText = container.read(tipsProvider).currentTip['text'];

      container.read(tipsProvider.notifier).nextTip();
      final nextIndex = container.read(tipsProvider).currentIndex;
      final nextTipText = container.read(tipsProvider).currentTip['text'];

      expect(nextIndex, equals((initialIndex + 1) % WellnessTips.totalTips));
      expect(nextTipText, isNot(equals(initialTipText)));
    });

    test('toggleSave bookmarks and un-bookmarks tips and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(tipsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(tipsProvider.notifier);
      const tipIndex = 3;

      expect(notifier.isSaved(tipIndex), isFalse);

      // Save tip
      await notifier.toggleSave(tipIndex);
      expect(notifier.isSaved(tipIndex), isTrue);
      expect(container.read(tipsProvider).savedIndices.contains(tipIndex), isTrue);

      // Verify SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      var saved = prefs.getStringList('saved_tips') ?? [];
      expect(saved.contains('3'), isTrue);

      // Un-save tip
      await notifier.toggleSave(tipIndex);
      expect(notifier.isSaved(tipIndex), isFalse);
      saved = prefs.getStringList('saved_tips') ?? [];
      expect(saved.contains('3'), isFalse);
    });

    test('getSavedTips returns formatted tip maps for all bookmarked indices', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(tipsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(tipsProvider.notifier);
      await notifier.toggleSave(0);
      await notifier.toggleSave(5);

      final savedTips = notifier.getSavedTips();
      expect(savedTips.length, equals(2));
      expect(savedTips[0]['text'], equals(WellnessTips.getTipAt(0)['text']));
      expect(savedTips[1]['text'], equals(WellnessTips.getTipAt(5)['text']));
    });
  });
}
