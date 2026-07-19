import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/notes_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotesNotifier - Quick Notes Unit Tests', () {
    test('initial state has no notes and is not loading after loading finishes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger provider read and wait for _load to complete
      container.read(notesProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(notesProvider);
      expect(state.notes, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('addNote adds a note to the list, sorts by newest, and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(notesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(notesProvider.notifier);
      await notifier.addNote('This is my first quick note!');
      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(notesProvider);
      expect(state.notes.length, equals(1));
      expect(state.notes.first.text, equals('This is my first quick note!'));

      // Add another note
      await notifier.addNote('This is a second note.');
      await Future.delayed(const Duration(milliseconds: 50));

      state = container.read(notesProvider);
      expect(state.notes.length, equals(2));
      // Newly added note should be first (sorted by newest)
      expect(state.notes.first.text, equals('This is a second note.'));

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('quick_notes') ?? [];
      expect(saved.length, equals(2));

      final decodedFirst = Map<String, dynamic>.from(jsonDecode(saved.first));
      // First in SharedPreferences list matches first in notifier state list
      expect(decodedFirst['text'], equals('This is a second note.'));
    });

    test('deleteNote removes note from state and SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(notesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(notesProvider.notifier);
      await notifier.addNote('Note to delete');
      await notifier.addNote('Note to keep');
      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(notesProvider);
      expect(state.notes.length, equals(2));
      final deleteId = state.notes.firstWhere((n) => n.text == 'Note to delete').id;

      await notifier.deleteNote(deleteId);
      await Future.delayed(const Duration(milliseconds: 50));

      state = container.read(notesProvider);
      expect(state.notes.length, equals(1));
      expect(state.notes.any((n) => n.text == 'Note to delete'), isFalse);
      expect(state.notes.first.text, equals('Note to keep'));

      // Check SharedPreferences list matches
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('quick_notes') ?? [];
      expect(saved.length, equals(1));
      final decoded = Map<String, dynamic>.from(jsonDecode(saved.first));
      expect(decoded['text'], equals('Note to keep'));
    });
  });
}
