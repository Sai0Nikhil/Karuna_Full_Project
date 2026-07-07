import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Choose Your Role – first screen after splash if not logged in.
/// Three portals: Citizen, NGO Staff, Veterinary Clinic
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String? _selected;

  final _roles = [
    _RoleOption(
      role: 'citizen',
      emoji: '🏙️',
      title: 'Citizen',
      subtitle: 'Report injured animals, donate & adopt',
      color: AppColors.teal,
      bgColor: AppColors.tealBg,
    ),
    _RoleOption(
      role: 'ngo',
      emoji: '🏥',
      title: 'NGO Staff',
      subtitle: 'Manage rescue cases & coordinate rescues',
      color: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
    ),
    _RoleOption(
      role: 'vet',
      emoji: '🩺',
      title: 'Veterinary Clinic',
      subtitle: 'Treat animals, manage slots & emergency requests',
      color: const Color(0xFF7C3AED),
      bgColor: const Color(0xFFF5F3FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Choose Your Role',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    const SizedBox(height: 6),
                    const Text('Select how you want to use Karuṇā',
                        style: TextStyle(fontSize: 14, color: AppColors.gray)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Role cards
              ..._roles.map((r) => _RoleCard(
                    option: r,
                    selected: _selected == r.role,
                    onTap: () => setState(() => _selected = r.role),
                  )),
              const Spacer(),
              // Continue button
              AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pushNamed(context, '/login', arguments: _selected),
                  child: const Text('Continue →'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? option.bgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? option.color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: option.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(option.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: selected ? option.color : AppColors.dark)),
                  const SizedBox(height: 3),
                  Text(option.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? option.color : Colors.transparent,
                border: Border.all(color: selected ? option.color : AppColors.divider, width: 2),
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String role, emoji, title, subtitle;
  final Color color, bgColor;
  const _RoleOption({
    required this.role, required this.emoji, required this.title,
    required this.subtitle, required this.color, required this.bgColor,
  });
}
