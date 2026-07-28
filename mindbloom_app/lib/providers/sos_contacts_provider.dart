import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSContact {
  final String id;
  final String name;
  final String number;
  final String relation;

  SOSContact({
    required this.id,
    required this.name,
    required this.number,
    required this.relation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'number': number,
        'relation': relation,
      };

  factory SOSContact.fromJson(Map<String, dynamic> json) {
    return SOSContact(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String,
      relation: json['relation'] as String? ?? 'Personal Contact',
    );
  }
}

class SOSContactsState {
  final List<SOSContact> contacts;
  final bool isLoading;

  const SOSContactsState({
    this.contacts = const [],
    this.isLoading = false,
  });

  SOSContactsState copyWith({
    List<SOSContact>? contacts,
    bool? isLoading,
  }) {
    return SOSContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SOSContactsNotifier extends StateNotifier<SOSContactsState> {
  static const _storageKey = 'custom_sos_contacts';

  SOSContactsNotifier() : super(const SOSContactsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final loaded = raw
        .map((s) => SOSContact.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    state = SOSContactsState(contacts: loaded, isLoading: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.contacts.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> addContact({
    required String name,
    required String number,
    required String relation,
  }) async {
    final contact = SOSContact(
      id: '${DateTime.now().millisecondsSinceEpoch}_${state.contacts.length}',
      name: name.trim(),
      number: number.trim(),
      relation: relation.trim(),
    );
    state = state.copyWith(contacts: [...state.contacts, contact]);
    await _save();
  }

  Future<void> deleteContact(String id) async {
    state = state.copyWith(
      contacts: state.contacts.where((c) => c.id != id).toList(),
    );
    await _save();
  }
}

final sosContactsProvider =
    StateNotifierProvider<SOSContactsNotifier, SOSContactsState>((ref) {
  return SOSContactsNotifier();
});
