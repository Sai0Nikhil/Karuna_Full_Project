import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'vet_cases_screen.dart';
import 'vet_slots_screen.dart';
import 'vet_tracking_screen.dart';
import 'vet_clinic_screen.dart';

/// Vet Clinic Portal – matches Figma "veterinary clinic home"
/// Bottom nav: Home | Cases | Slots | Tracking | Clinic
class VetHome extends StatefulWidget {
  const VetHome({super.key});
  @override
  State<VetHome> createState() => _VetHomeState();
}

class _VetHomeState extends State<VetHome> {
  int _tab = 0;

  final List<Widget> _pages = const [
    _VetDashboard(),
    VetCasesScreen(),
    VetSlotsScreen(),
    VetTrackingScreen(),
    VetClinicScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _VetBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Figma-accurate Vet bottom nav ─────────────────────────────────────────────
class _VetBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _VetBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
      (Icons.description_outlined, Icons.description, 'Cases'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'Slots'),
      (Icons.timeline_outlined, Icons.timeline, 'Tracking'),
      (Icons.local_hospital_outlined, Icons.local_hospital, 'Clinic'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(active ? item.$2 : item.$1,
                          size: 22,
                          color: active ? Colors.white : Colors.white54),
                      const SizedBox(height: 2),
                      Text(item.$3,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            color: active ? Colors.white : Colors.white54,
                          )),
                      const SizedBox(height: 2),
                      if (active)
                        Container(width: 20, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))
                      else
                        const SizedBox(height: 3),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Vet Dashboard (matches Figma "veterinary clinic home") ────────────────────
class _VetDashboard extends StatefulWidget {
  const _VetDashboard();
  @override
  State<_VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<_VetDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchAllCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final caseProvider = context.watch<CaseProvider>();
    final critical = caseProvider.allCases.where((c) => c.severity == 'critical').toList();
    final urgent = caseProvider.allCases.where((c) => c.severity == 'urgent').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => context.read<CaseProvider>().fetchAllCases(),
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(24)),
                      child: const Center(child: Text('🩺', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Dr. ${auth.user?.name.split(' ').first ?? 'Neha'}',
                            style: const TextStyle(fontSize: 14, color: AppColors.teal, fontWeight: FontWeight.w500)),
                        const Text('PawCare Veterinary Clinic',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined, color: AppColors.gray),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (mounted) Navigator.pushReplacementNamed(context, '/');
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats row ─────────────────────────────────────────────
                  Row(
                    children: [
                      _vetStatCard('1245', 'Animals Treated', Icons.pets_outlined),
                      const SizedBox(width: 10),
                      _vetStatCard('${critical.length + urgent.length}', 'Emergency Cases', Icons.emergency_outlined, color: AppColors.critical),
                      const SizedBox(width: 10),
                      _vetStatCard('36', 'Volunteers', Icons.people_outline, color: AppColors.active),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Emergency Requests ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Emergency Requests',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('See all', style: TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (caseProvider.loading)
                    const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  else ...[
                    ...[...critical, ...urgent].take(3).map((c) => _EmergencyCard(
                          emoji: c.speciesEmoji,
                          title: '${c.species ?? 'Animal'} - ${c.injuryType ?? 'Injured'}',
                          location: c.locationLabel ?? 'Unknown',
                          caseId: '#K${c.id.toString().padLeft(3, '0')}',
                          status: c.severity ?? 'urgent',
                        )),
                    if (critical.isEmpty && urgent.isEmpty)
                      const _EmergencyCard(emoji: '🐕', title: 'Injured Dog', location: 'Koramangala', caseId: '#K001', status: 'critical'),
                  ],
                  const SizedBox(height: 20),

                  // ── Nearby Rescues map placeholder ───────────────────────
                  const Text('Nearby Rescues',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 10),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEAF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.teal),
                    ),
                    child: Stack(
                      children: [
                        const Center(child: Text('🗺️', style: TextStyle(fontSize: 48))),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(16)),
                            child: const Center(
                              child: Text('3 active rescues within 2 km',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Actions ────────────────────────────────────────
                  Row(
                    children: [
                      _vetQuickAction(Icons.description_outlined, 'View Report', () {}),
                      const SizedBox(width: 14),
                      _vetQuickAction(Icons.emergency_outlined, 'Emergency', () {}, color: AppColors.critical),
                      const SizedBox(width: 14),
                      _vetQuickAction(Icons.people_outline, 'Contact NGO', () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vetStatCard(String value, String label, IconData icon, {Color color = AppColors.teal}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.gray), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _vetQuickAction(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.teal}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Emergency case card ───────────────────────────────────────────────────────
class _EmergencyCard extends StatelessWidget {
  final String emoji, title, location, caseId, status;
  const _EmergencyCard({
    required this.emoji, required this.title, required this.location,
    required this.caseId, required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.tealBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.teal),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(location, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                const SizedBox(height: 2),
                Text(caseId, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ],
            ),
          ),
          StatusBadge(status),
        ],
      ),
    );
  }
}
