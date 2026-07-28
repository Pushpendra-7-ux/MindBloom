import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/sos_contacts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SOSContactsNotifier - Custom Emergency Contacts Unit Tests', () {
    test('initial state has no custom contacts and finishes loading', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sosContactsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(sosContactsProvider);
      expect(state.contacts, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('addContact adds contact to state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sosContactsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(sosContactsProvider.notifier);
      await notifier.addContact(
        name: 'Dr. Sarah',
        number: '9876543210',
        relation: 'Therapist',
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(sosContactsProvider);
      expect(state.contacts.length, equals(1));
      expect(state.contacts.first.name, equals('Dr. Sarah'));
      expect(state.contacts.first.number, equals('9876543210'));
      expect(state.contacts.first.relation, equals('Therapist'));

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_sos_contacts') ?? [];
      expect(saved.length, equals(1));

      final decoded = Map<String, dynamic>.from(jsonDecode(saved.first));
      expect(decoded['name'], equals('Dr. Sarah'));
      expect(decoded['number'], equals('9876543210'));
      expect(decoded['relation'], equals('Therapist'));
    });

    test('deleteContact removes contact from state and SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sosContactsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(sosContactsProvider.notifier);
      await notifier.addContact(
        name: 'Contact To Delete',
        number: '1111111111',
        relation: 'Friend',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await notifier.addContact(
        name: 'Contact To Keep',
        number: '2222222222',
        relation: 'Family',
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(sosContactsProvider);
      expect(state.contacts.length, equals(2));

      final deleteId = state.contacts.firstWhere((c) => c.name == 'Contact To Delete').id;
      await notifier.deleteContact(deleteId);
      await Future.delayed(const Duration(milliseconds: 50));

      state = container.read(sosContactsProvider);
      expect(state.contacts.length, equals(1));
      expect(state.contacts.first.name, equals('Contact To Keep'));

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_sos_contacts') ?? [];
      expect(saved.length, equals(1));
      final decoded = Map<String, dynamic>.from(jsonDecode(saved.first));
      expect(decoded['name'], equals('Contact To Keep'));
    });
  });
}
