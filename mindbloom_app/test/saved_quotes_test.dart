import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Saved Quotes Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'favorited_quotes': [
          'The only journey is the one within.~Rainer Maria Rilke',
          'Act as if what you do makes a difference. It does.~William James',
        ]
      });
    });

    test('Loads and parses saved quotes correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final favoritedList = prefs.getStringList('favorited_quotes') ?? [];

      expect(favoritedList.length, equals(2));

      final parsed = favoritedList.map((q) {
        final parts = q.split('~');
        final text = parts.isNotEmpty ? parts[0] : '';
        final author = parts.length > 1 ? parts[1] : 'Unknown';
        return {'text': text, 'author': author, 'raw': q};
      }).toList();

      expect(parsed[0]['text'], equals('The only journey is the one within.'));
      expect(parsed[0]['author'], equals('Rainer Maria Rilke'));
      expect(parsed[1]['text'], equals('Act as if what you do makes a difference. It does.'));
      expect(parsed[1]['author'], equals('William James'));
    });

    test('Add quote to favorited list', () async {
      final prefs = await SharedPreferences.getInstance();
      final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
      
      const newQuote = 'Believe you can and you are halfway there.~Theodore Roosevelt';
      favoritedList.add(newQuote);
      await prefs.setStringList('favorited_quotes', favoritedList);

      final updatedList = prefs.getStringList('favorited_quotes') ?? [];
      expect(updatedList.length, equals(3));
      expect(updatedList.last, equals(newQuote));
    });

    test('Remove single quote from favorited list', () async {
      final prefs = await SharedPreferences.getInstance();
      final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
      
      const toRemove = 'The only journey is the one within.~Rainer Maria Rilke';
      favoritedList.remove(toRemove);
      await prefs.setStringList('favorited_quotes', favoritedList);

      final updatedList = prefs.getStringList('favorited_quotes') ?? [];
      expect(updatedList.length, equals(1));
      expect(updatedList.contains(toRemove), isFalse);
    });

    test('Clear all saved quotes', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('favorited_quotes');

      final updatedList = prefs.getStringList('favorited_quotes');
      expect(updatedList, isNull);
    });
  });
}
