import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/appointment_model.dart';

void main() {
  group('AppointmentModel Tests', () {
    test('fromJson parses full data correctly', () {
      final json = {
        '_id': 'apt_123',
        'doctorName': 'Dr. Elizabeth Blackwell',
        'specialty': 'psychiatrist',
        'clinicName': 'Hope Valley Mental Health',
        'date': '2026-06-28T14:30:00.000Z',
        'time': '2:30 PM',
        'duration': 45,
        'status': 'scheduled',
        'notes': 'First session consultation',
        'reminder': true,
      };

      final apt = AppointmentModel.fromJson(json);

      expect(apt.id, equals('apt_123'));
      expect(apt.doctorName, equals('Dr. Elizabeth Blackwell'));
      expect(apt.specialty, equals('psychiatrist'));
      expect(apt.clinicName, equals('Hope Valley Mental Health'));
      expect(apt.date.year, equals(2026));
      expect(apt.date.month, equals(6));
      expect(apt.date.day, equals(28));
      expect(apt.time, equals('2:30 PM'));
      expect(apt.duration, equals(45));
      expect(apt.status, equals('scheduled'));
      expect(apt.notes, equals('First session consultation'));
      expect(apt.reminder, isTrue);
    });

    test('fromJson falls back to defaults for missing optional fields', () {
      final json = {
        'doctorName': 'Dr. Robert',
        'date': '2026-06-28T10:00:00.000Z',
        'time': '10:00 AM',
      };

      final apt = AppointmentModel.fromJson(json);

      expect(apt.id, isNull);
      expect(apt.doctorName, equals('Dr. Robert'));
      expect(apt.specialty, equals('general')); // default
      expect(apt.clinicName, equals('')); // default
      expect(apt.duration, equals(60)); // default
      expect(apt.status, equals('scheduled')); // default
      expect(apt.notes, equals('')); // default
      expect(apt.reminder, isTrue); // default
    });

    test('toJson serializes data correctly', () {
      final date = DateTime(2026, 6, 28, 11, 0);
      final apt = AppointmentModel(
        id: 'apt_555',
        doctorName: 'Dr. Jane',
        specialty: 'therapist',
        clinicName: 'Serene Clinic',
        date: date,
        time: '11:00 AM',
        duration: 30,
        status: 'completed',
        notes: 'Follow-up discussion',
        reminder: false,
      );

      final json = apt.toJson();

      expect(json['doctorName'], equals('Dr. Jane'));
      expect(json['specialty'], equals('therapist'));
      expect(json['clinicName'], equals('Serene Clinic'));
      expect(json['date'], equals(date.toIso8601String()));
      expect(json['time'], equals('11:00 AM'));
      expect(json['duration'], equals(30));
      expect(json['notes'], equals('Follow-up discussion'));
      expect(json['reminder'], isFalse);
    });
  });
}
