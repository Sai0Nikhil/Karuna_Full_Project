import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

/// Vet Clinic Profile/Info screen
class VetClinicScreen extends StatelessWidget {
  const VetClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinic Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.gray),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Clinic header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(40)),
                    child: const Center(child: Text('🏥', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 12),
                  const Text('PawCare Veterinary Clinic',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 4),
                  Text('Dr. ${auth.user?.name ?? 'Neha Sharma'}',
                      style: const TextStyle(fontSize: 14, color: AppColors.teal, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Koramangala, Bangalore · VCNO-2024-1245',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge('✅ Verified', AppColors.resolvedBg, AppColors.resolved),
                      const SizedBox(width: 8),
                      _badge('⭐ 4.8 Rating', AppColors.urgentBg, AppColors.urgent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info sections
            _infoCard('Clinic Details', [
              _InfoRow(Icons.location_on_outlined, 'Address', '12, 3rd Cross, Koramangala, Bangalore - 560034'),
              _InfoRow(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
              _InfoRow(Icons.email_outlined, 'Email', 'pawcare@vetclinic.in'),
              _InfoRow(Icons.access_time_outlined, 'Hours', 'Mon–Sat: 9AM – 6PM'),
            ]),
            const SizedBox(height: 12),

            _infoCard('Specialisations', [
              _InfoRow(Icons.pets, 'Species', 'Dogs, Cats, Birds, Rabbits'),
              _InfoRow(Icons.medical_services_outlined, 'Services', 'Surgery, Vaccination, Emergency Care'),
              _InfoRow(Icons.science_outlined, 'Lab', 'In-house diagnostics available'),
            ]),
            const SizedBox(height: 12),

            // Emergency toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_outlined, color: AppColors.critical),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Emergency Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
                      Text('Accept emergency cases from NGOs', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                    ]),
                  ),
                  Switch(value: true, onChanged: (_) {}, activeColor: AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoCard(String title, List<_InfoRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.icon, size: 16, color: AppColors.teal),
                    const SizedBox(width: 10),
                    SizedBox(width: 80, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.gray))),
                    Expanded(child: Text(r.value, style: const TextStyle(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
}

// Needed constants
const Color resolvedBg = AppColors.resolvedBg;
const Color resolved = AppColors.resolved;
