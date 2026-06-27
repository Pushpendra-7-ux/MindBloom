import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await ApiService().getAppointments();
      setState(() {
        _appointments = (response.data['appointments'] as List)
            .map((e) => AppointmentModel.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAppointmentStatus(String id, String status) async {
    try {
      await ApiService().updateAppointment(id, {'status': status});
      _loadAppointments();
    } catch (_) {}
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      await ApiService().deleteAppointment(id);
      _loadAppointments();
    } catch (_) {}
  }

  void _showOptionsSheet(AppointmentModel apt) {
    if (apt.id == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isPast = apt.date.isBefore(DateTime.now());
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                apt.doctorName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${apt.specialty[0].toUpperCase()}${apt.specialty.substring(1)} • ${apt.time}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if (apt.clinicName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  apt.clinicName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 24),
              if (apt.status == 'scheduled' && !isPast) ...[
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: AppColors.coral),
                  title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateAppointmentStatus(apt.id!, 'cancelled');
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Delete Appointment', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteAppointment(apt.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    final doctorController = TextEditingController();
    final clinicController = TextEditingController();
    final notesController = TextEditingController();
    final timeController = TextEditingController();
    String specialty = 'therapist';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('New Appointment', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextFormField(controller: doctorController, decoration: const InputDecoration(hintText: 'Doctor name', prefixIcon: Icon(Icons.person_outline, size: 20))),
                const SizedBox(height: 12),
                TextFormField(controller: clinicController, decoration: const InputDecoration(hintText: 'Clinic name', prefixIcon: Icon(Icons.local_hospital_outlined, size: 20))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: specialty,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.medical_services_outlined, size: 20)),
                  items: ['psychiatrist', 'psychologist', 'therapist', 'counselor', 'general']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                      .toList(),
                  onChanged: (v) => setModalState(() => specialty = v!),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setModalState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today, size: 20)),
                    child: Text(DateFormat('MMM d, y').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: timeController, decoration: const InputDecoration(hintText: 'Time (e.g. 10:00 AM)', prefixIcon: Icon(Icons.access_time, size: 20))),
                const SizedBox(height: 12),
                TextFormField(controller: notesController, maxLines: 2, decoration: const InputDecoration(hintText: 'Notes (optional)', prefixIcon: Icon(Icons.notes, size: 20))),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Book Appointment',
                  color: AppColors.softGreen,
                  onPressed: () async {
                    if (doctorController.text.isEmpty) return;
                    try {
                      await ApiService().createAppointment({
                        'doctorName': doctorController.text,
                        'specialty': specialty,
                        'clinicName': clinicController.text,
                        'date': selectedDate.toIso8601String(),
                        'time': timeController.text.isNotEmpty ? timeController.text : '10:00 AM',
                        'notes': notesController.text,
                      });
                      if (context.mounted) Navigator.pop(context);
                      _loadAppointments();
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_appointment',
        onPressed: _showAddDialog,
        backgroundColor: AppColors.softGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No appointments', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Tap + to book one', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final apt = _appointments[index];
                    final isPast = apt.date.isBefore(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: (isPast ? Colors.grey : AppColors.primaryPurple).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat('d').format(apt.date), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isPast ? Colors.grey : AppColors.primaryPurple)),
                                  Text(DateFormat('MMM').format(apt.date), style: TextStyle(fontSize: 10, color: isPast ? Colors.grey : AppColors.primaryPurple)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(apt.doctorName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${apt.specialty[0].toUpperCase()}${apt.specialty.substring(1)} • ${apt.time}',
                                    style: Theme.of(context).textTheme.bodySmall),
                                  if (apt.clinicName.isNotEmpty)
                                    Text(apt.clinicName, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(apt.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(apt.status, style: TextStyle(fontSize: 11, color: _statusColor(apt.status), fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled': return AppColors.calmBlue;
      case 'completed': return AppColors.softGreen;
      case 'cancelled': return AppColors.coral;
      default: return AppColors.warmAmber;
    }
  }
}
