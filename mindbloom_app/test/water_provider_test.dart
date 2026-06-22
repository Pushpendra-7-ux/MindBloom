import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/water_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaterNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state loads with 0 cups and 8 goal', () async {
      final notifier = WaterNotifier();
      await Future.delayed(Duration.zero);
      expect(notifier.state.cups, equals(0));
      expect(notifier.state.goal, equals(8));
    });

    test('increment increases cups by 1', () async {
      final notifier = WaterNotifier();
      await Future.delayed(Duration.zero);
      await notifier.increment();
      expect(notifier.state.cups, equals(1));
    });

    test('decrement decreases cups by 1', () async {
      final notifier = WaterNotifier();
      await Future.delayed(Duration.zero);
      await notifier.increment();
      await notifier.increment();
      expect(notifier.state.cups, equals(2));
      
      await notifier.decrement();
      expect(notifier.state.cups, equals(1));
    });

    test('decrement does not go below 0', () async {
      final notifier = WaterNotifier();
      await Future.delayed(Duration.zero);
      await notifier.decrement();
      expect(notifier.state.cups, equals(0));
    });
  });
}
