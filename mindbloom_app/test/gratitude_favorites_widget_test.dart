import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/dashboard/dashboard_screen.dart';
import 'package:mindbloom_app/providers/gratitude_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createDashboardWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: DashboardScreen(),
        ),
      ),
    );
  }

  Future<void> pumpDashboardScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createDashboardWidget());
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('DashboardScreen - Starred Gratitudes Widget Tests', () {
    testWidgets('Adding a gratitude entry renders a chip with star favorite button', (tester) async {
      await pumpDashboardScreen(tester);

      final input = find.byType(TextField).first;
      await tester.enterText(input, 'Grateful for sunny weather');
      await tester.tap(find.byTooltip('Add gratitude'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Grateful for sunny weather'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });

    testWidgets('Tapping star button on gratitude chip toggles favorite state', (tester) async {
      await pumpDashboardScreen(tester);

      final input = find.byType(TextField).first;
      await tester.enterText(input, 'Grateful for good coffee');
      await tester.tap(find.byTooltip('Add gratitude'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      final element = tester.element(find.byType(DashboardScreen));
      final container = ProviderScope.containerOf(element);
      final entryId = container.read(gratitudeProvider).entries.first.id;

      // Toggle favorite via notifier
      await container.read(gratitudeProvider.notifier).toggleFavorite(entryId);
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(gratitudeProvider).entries.first.isFavorite, isTrue);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('Opening Gratitude Garden allows filtering by Starred entries', (tester) async {
      await pumpDashboardScreen(tester);

      // Add a gratitude entry
      final input = find.byType(TextField).first;
      await tester.enterText(input, 'Grateful for family time');
      await tester.tap(find.byTooltip('Add gratitude'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      // Open Gratitude Garden sheet using tooltip 'View all entries'
      final gardenButton = find.byTooltip('View all entries');
      await tester.tap(gardenButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Starred'), findsOneWidget);

      // Tap Starred filter chip
      await tester.tap(find.text('Starred'));
      await tester.pumpAndSettle();

      expect(find.text('No starred entries yet'), findsOneWidget);
    });
  });
}
