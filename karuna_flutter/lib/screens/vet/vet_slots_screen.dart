import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Vet Slots – appointment/slot booking management
/// Matches Figma "vet slot" screen
class VetSlotsScreen extends StatelessWidget {
  const VetSlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Slots'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.teal),
            onPressed: () => _showAddSlotDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker strip
            const Text('Select Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (ctx, i) {
                  final day = days[i];
                  final active = i == 0;
                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Container(
                    width: 52,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.teal : AppColors.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayNames[day.weekday - 1],
                            style: TextStyle(fontSize: 10, color: active ? Colors.white70 : AppColors.gray)),
                        const SizedBox(height: 4),
                        Text('${day.day}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: active ? Colors.white : AppColors.dark)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Slots
            const Text('Available Slots', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            ..._slots.map((slot) => _SlotCard(slot: slot)),
            const SizedBox(height: 20),

            // Booked appointments
            const Text('Booked Appointments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            ..._booked.map((appt) => _AppointmentCard(appt: appt)),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Duration (minutes)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Slot')),
          ],
        ),
      ),
    );
  }

  static const _slots = ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM'];
  static const _booked = [
    _Appointment('Rex (Dog)', 'Vaccination', '09:00 AM', 'Priya S.'),
    _Appointment('Luna (Cat)', 'Follow-up check', '10:00 AM', 'Rahul K.'),
    _Appointment('Brownie (Dog)', 'Wound dressing', '11:00 AM', 'Anita M.'),
  ];
}

class _SlotCard extends StatelessWidget {
  final String time;
  const _SlotCard({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.teal, size: 18),
          const SizedBox(width: 10),
          Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.dark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(20)),
            child: const Text('Available', style: TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final _Appointment appt;
  const _AppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.pets, color: AppColors.teal, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt.patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(appt.reason, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                const SizedBox(height: 2),
                Text('By ${appt.owner}', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ],
            ),
          ),
          Text(appt.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal)),
        ],
      ),
    );
  }
}

class _Appointment {
  final String patientName, reason, time, owner;
  const _Appointment(this.patientName, this.reason, this.time, this.owner);
}
