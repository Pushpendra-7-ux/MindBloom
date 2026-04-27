class AppointmentModel {
  final String? id;
  final String doctorName;
  final String specialty;
  final String clinicName;
  final DateTime date;
  final String time;
  final int duration;
  final String status;
  final String notes;
  final bool reminder;

  AppointmentModel({
    this.id,
    required this.doctorName,
    required this.specialty,
    this.clinicName = '',
    required this.date,
    required this.time,
    this.duration = 60,
    this.status = 'scheduled',
    this.notes = '',
    this.reminder = true,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] ?? json['id'],
      doctorName: json['doctorName'] ?? '',
      specialty: json['specialty'] ?? 'general',
      clinicName: json['clinicName'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? '',
      duration: json['duration'] ?? 60,
      status: json['status'] ?? 'scheduled',
      notes: json['notes'] ?? '',
      reminder: json['reminder'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'doctorName': doctorName,
    'specialty': specialty,
    'clinicName': clinicName,
    'date': date.toIso8601String(),
    'time': time,
    'duration': duration,
    'notes': notes,
    'reminder': reminder,
  };
}
