import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/mood_history/mood_history_screen.dart';
import 'package:mindbloom_app/providers/mood_provider.dart';
import 'package:mindbloom_app/models/mood_model.dart';

// Fake MoodNotifier populated with test logs
class FakeMoodNotifier extends MoodNotifier {
  FakeMoodNotifier() : super() {
    state = MoodState(
      history: [
        MoodLog(
          id: '1',
          moodScore: 9,
          emoji: '😄',
          feelings: ['Happy', 'Joyful'],
          journal: 'Had an amazing day with friends at the park! We played soccer, had a picnic under the tree, ate delicious food, and talked for hours. It was so much fun!',
          createdAt: DateTime.now(),
        ),
        MoodLog(
          id: '2',
          moodScore: 5,
          emoji: '😐',
          feelings: ['Calm', 'Tired'],
          journal: 'A very typical workday. Nothing special happened.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        MoodLog(
          id: '3',
          moodScore: 2,
          emoji: '😢',
          feelings: ['Sad', 'Anxious'],
          journal: 'Felt quite overwhelmed with tasks today.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  @override
  Future<void> fetchLatestMood() async {}

  @override
  Future<void> fetchWeeklyData() async {}

  @override
  Future<void> fetchMoodHistory({int days = 30}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup mock channels for flutter_secure_storage
  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async {
    return null;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Mood History search, filter, expand/collapse, and empty state tests', (WidgetTester tester) async {
    // Set viewport size
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moodProvider.overrideWith((ref) => FakeMoodNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MoodHistoryScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State verification
    expect(find.textContaining('and talk...'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);
    expect(find.textContaining('Had an amazing day'), findsNWidgets(2));
    expect(find.textContaining('A very typical workday'), findsOneWidget);
    expect(find.textContaining('Felt quite overwhelmed'), findsOneWidget);

    // 2. Search query test (Search text: "typical")
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'typical');
    await tester.pumpAndSettle();

    // Only "typical workday" log should be visible
    expect(find.textContaining('Had an amazing day'), findsNothing);
    expect(find.textContaining('A very typical workday'), findsOneWidget);
    expect(find.textContaining('Felt quite overwhelmed'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // All should be visible again
    expect(find.textContaining('Had an amazing day'), findsNWidgets(2));
    expect(find.textContaining('A very typical workday'), findsOneWidget);
    expect(find.textContaining('Felt quite overwhelmed'), findsOneWidget);

    // 3. Category Filter test (Tap "Positive")
    final positiveFilter = find.text('Positive');
    expect(positiveFilter, findsOneWidget);
    await tester.tap(positiveFilter);
    await tester.pumpAndSettle();

    // Only Positive log should be visible
    expect(find.textContaining('Had an amazing day'), findsNWidgets(2));
    expect(find.textContaining('A very typical workday'), findsNothing);
    expect(find.textContaining('Felt quite overwhelmed'), findsNothing);

    // Tap "All" to reset filter
    final allFilter = find.text('All').last;
    expect(allFilter, findsOneWidget);
    await tester.tap(allFilter);
    await tester.pumpAndSettle();

    // 4. Empty State & Reset Button test
    await tester.enterText(searchField, 'extraterrestrial');
    await tester.pumpAndSettle();

    // Verify empty search results are visible
    expect(find.text('No matching results'), findsOneWidget);
    expect(find.text('Try adjusting your search query or changing filters.'), findsOneWidget);

    // Tap reset button
    final resetBtn = find.text('Reset Search & Filters');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // Verify search field is cleared and all entries show again
    expect(find.text('No matching results'), findsNothing);
    expect(find.textContaining('Had an amazing day'), findsNWidgets(2));
    expect(find.textContaining('A very typical workday'), findsOneWidget);
    expect(find.textContaining('Felt quite overwhelmed'), findsOneWidget);

    // 5. Expand & Collapse test
    // Find 'Read more' text
    final readMoreText = find.text('Read more');
    expect(readMoreText, findsOneWidget);

    // Tap 'Read more'
    await tester.tap(readMoreText);
    await tester.pumpAndSettle();

    // Now full journal text should be visible, and 'Show less' should be visible
    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('Had an amazing day with friends at the park! We played soccer, had a picnic under the tree, ate delicious food, and talked for hours. It was so much fun!'), findsOneWidget);

    // Tap 'Show less'
    final showLessText = find.text('Show less');
    await tester.tap(showLessText);
    await tester.pumpAndSettle();

    // Verify it is collapsed again
    expect(find.text('Read more'), findsOneWidget);
  });
}
