import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/diamond_background.dart';

class _Role {
  final String key, emoji, title, subtitle;
  final Color color;
  const _Role(this.key, this.emoji, this.title, this.subtitle, this.color);
}

const _roles = [
  _Role('citizen', '🏙️', 'Citizen', 'Report injured animals, donate & adopt', Color(0xFF0F766E)),
  _Role('ngo', '🏥', 'NGO Staff', 'Manage rescue cases & coordinate', Color(0xFF2563EB)),
  _Role('volunteer', '🦺', 'Volunteer Responder', 'Accept dispatch & rescue animals', Color(0xFFD97706)),
  _Role('vet', '🩺', 'Veterinary Clinic', 'Treat animals & manage slots', Color(0xFF7C3AED)),
];

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});
  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LightDiamondBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Center(child: Text('Karuṇā', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.teal))),
                const SizedBox(height: 32),
                Text('Choose Your Role', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 4),
                Text('Select how you want to use Karuṇā', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray)),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(children: _roles.map((r) => _RoleCard(
                    role: r, selected: _selected == r.key,
                    onTap: () => setState(() => _selected = r.key),
                  )).toList()),
                ),
                ElevatedButton(
                  onPressed: _selected == null ? null : () => Navigator.pushNamed(context, '/login', arguments: _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected != null ? AppColors.teal : Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: Text('Continue  →', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _Role role; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: selected ? role.color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: role.color, width: 4),
            top: BorderSide(color: selected ? role.color.withOpacity(0.3) : Colors.transparent, width: 1),
            right: BorderSide(color: selected ? role.color.withOpacity(0.3) : Colors.transparent, width: 1),
            bottom: BorderSide(color: selected ? role.color.withOpacity(0.3) : Colors.transparent, width: 1),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: role.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
              const SizedBox(height: 3),
              Text(role.subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray)),
            ])),
            Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: selected ? role.color : AppColors.gray),
          ]),
        ),
      ),
    );
  }
}
