import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../models/case_model.dart';
import '../../utils/app_colors.dart';
import 'report_flow.dart';
import 'my_cases_screen.dart';
import 'donate_screen.dart';
import 'adopt_screen.dart';
import 'first_aid_screen.dart';
import 'sita_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Citizen Home – Root shell with IndexedStack + bottom nav
// ─────────────────────────────────────────────────────────────────────────────
class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});
  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _tab = 0; // 0=Home 1=My Cases 2=Community 3=Profile

  void _onNavTap(int i) {
    if (i == 2) {
      // Centre Report button → push as modal
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFlow()));
      return;
    }
    setState(() => _tab = i < 2 ? i : i - 1); // skip the centre slot
  }

  static const _pages = <Widget>[
    _HomeContent(),
    MyCasesScreen(),
    _CommunityPlaceholder(),
    _ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _CitizenBottomNav(
        currentIndex: _tab,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation – 5 slots, centre is orange FAB-style Report button
// ─────────────────────────────────────────────────────────────────────────────
class _CitizenBottomNav extends StatelessWidget {
  final int currentIndex; // 0-3 (Home, MyCases, Community, Profile)
  final ValueChanged<int> onTap;
  const _CitizenBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Home
              _navItem(icon: Icons.home_rounded, label: 'Home', index: 0, navIndex: 0, onTap: onTap, currentIndex: currentIndex),
              // My Cases
              _navItem(icon: Icons.pets_rounded, label: 'Rescues', index: 1, navIndex: 1, onTap: onTap, currentIndex: currentIndex),
              // Centre Report button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.40), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 2),
                      Text('Report', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFFF5722))),
                    ],
                  ),
                ),
              ),
              // Community
              _navItem(icon: Icons.people_rounded, label: 'Community', index: 3, navIndex: 2, onTap: onTap, currentIndex: currentIndex),
              // Profile
              _navItem(icon: Icons.person_rounded, label: 'Profile', index: 4, navIndex: 3, onTap: onTap, currentIndex: currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    required int navIndex,
    required ValueChanged<int> onTap,
    required int currentIndex,
  }) {
    final active = currentIndex == navIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.teal.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: active ? AppColors.teal : AppColors.gray, size: 22),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.teal : AppColors.gray,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Content Widget
// ─────────────────────────────────────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent();
  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchOpenCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final caseProvider = context.watch<CaseProvider>();
    final firstName = auth.user?.name.split(' ').first ?? 'there';
    final fullName = auth.user?.name ?? 'Arjun Sharma';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => context.read<CaseProvider>().fetchOpenCases(),
        child: CustomScrollView(
          slivers: [
            // ── Teal header ──────────────────────────────────────────────
            SliverToBoxAdapter(child: _TealHeader(firstName: firstName, fullName: fullName)),

            // ── Body ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Report Emergency card
                  _ReportEmergencyCard(),
                  const SizedBox(height: 20),

                  // Quick actions 2x2 grid
                  _SectionTitle(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),
                  const SizedBox(height: 24),

                  // Recent Cases Nearby
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Cases Nearby',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text('VIEW ALL',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (caseProvider.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.teal)))
                  else if (caseProvider.openCases.isEmpty)
                    _EmptyState()
                  else
                    ...caseProvider.openCases.take(6).map((c) => _NearCaseCard(caseModel: c)),

                  const SizedBox(height: 8),

                  // Sita Chat banner
                  _SitaBanner(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Teal header ──────────────────────────────────────────────────────────────
class _TealHeader extends StatelessWidget {
  final String firstName;
  final String fullName;
  const _TealHeader({required this.firstName, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D5C56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              // Row: hamburger | title | avatar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Karuṇā',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Greeting
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning!',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text(fullName,
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dark teal search bar
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/citizen/vets'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A4F4A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: const Color(0xFF7ECAC5), size: 20),
                      const SizedBox(width: 10),
                      Text('Search rescues, clinics, or vets...',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7ECAC5))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Report Emergency Card ─────────────────────────────────────────────────────
class _ReportEmergencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFlow())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5230), Color(0xFF0F766E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            // Paw icon in white circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🐾', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Emergency',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Help an animal in distress',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.80))),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title helper ──────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark));
  }
}

// ── Quick Actions 2×2 Grid ────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final _actions = const [
    _ActionData(emoji: '💛', label: 'Donate', iconBg: Color(0xFFEFF6FF), iconColor: Color(0xFF3B82F6), route: '/citizen/donate'),
    _ActionData(emoji: '🐾', label: 'Adopt', iconBg: Color(0xFFD1FAE5), iconColor: Color(0xFF10B981), route: '/citizen/adopt'),
    _ActionData(emoji: '🩹', label: 'First Aid', iconBg: Color(0xFFF3E8FF), iconColor: Color(0xFF8B5CF6), route: '/citizen/firstaid'),
    _ActionData(emoji: '📋', label: 'My Cases', iconBg: Color(0xFFDDF3F2), iconColor: Color(0xFF0F766E), route: '/citizen/cases'),
  ];

  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _actions.map((a) => _QuickActionTile(data: a)).toList(),
    );
  }
}

class _ActionData {
  final String emoji, label, route;
  final Color iconBg, iconColor;
  const _ActionData({required this.emoji, required this.label, required this.iconBg, required this.iconColor, required this.route});
}

class _QuickActionTile extends StatelessWidget {
  final _ActionData data;
  const _QuickActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, data.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: data.iconBg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            Text(data.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
          ],
        ),
      ),
    );
  }
}

// ── Nearby Case Card ──────────────────────────────────────────────────────────
class _NearCaseCard extends StatelessWidget {
  final CaseModel caseModel;
  const _NearCaseCard({required this.caseModel});

  String _timeAgo(String? iso) {
    if (iso == null) return 'Just now';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = caseModel.severity?.toLowerCase() == 'critical';
    final isStable = caseModel.severity?.toLowerCase() == 'routine';
    final statusText = _statusLabel(caseModel.status ?? 'reported');
    final timeAgo = _timeAgo(caseModel.createdAt);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/citizen/case', arguments: caseModel.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: SizedBox(
                width: 80,
                height: 90,
                child: caseModel.imageDataUrl != null && caseModel.imageDataUrl!.isNotEmpty
                    ? Image.network(
                        'https://picsum.photos/seed/${caseModel.id}/80/90',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _animalPlaceholder(caseModel.speciesEmoji),
                      )
                    : _animalPlaceholder(caseModel.speciesEmoji),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${caseModel.speciesEmoji} ${caseModel.species ?? 'Animal'} – ${caseModel.injuryType ?? 'Injury'}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Severity pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCritical ? AppColors.criticalBg : (isStable ? AppColors.resolvedBg : AppColors.urgentBg),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCritical ? 'CRITICAL' : (isStable ? 'STABLE' : 'URGENT'),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isCritical ? AppColors.critical : (isStable ? AppColors.resolved : AppColors.urgent),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.gray, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            caseModel.locationLabel ?? 'Unknown location',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.gray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusChip(status: caseModel.status ?? 'reported'),
                        const Spacer(),
                        Text(timeAgo, style: GoogleFonts.inter(fontSize: 10, color: AppColors.gray)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _animalPlaceholder(String emoji) {
    return Container(
      color: AppColors.tealBg,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
    );
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'assigned': return 'RESCUER ON WAY';
      case 'in_treatment':
      case 'at_clinic': return 'TREATED';
      case 'discharged': return 'DISCHARGED';
      default: return s.toUpperCase().replaceAll('_', ' ');
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; IconData icon; String label;
    switch (status.toLowerCase()) {
      case 'assigned':
        bg = AppColors.activeBg; fg = AppColors.active;
        icon = Icons.directions_run_rounded; label = 'RESCUER ON WAY';
        break;
      case 'in_treatment':
      case 'at_clinic':
        bg = AppColors.resolvedBg; fg = AppColors.resolved;
        icon = Icons.medical_services_rounded; label = 'TREATED';
        break;
      case 'discharged':
        bg = AppColors.resolvedBg; fg = AppColors.resolved;
        icon = Icons.check_circle_rounded; label = 'DISCHARGED';
        break;
      default:
        bg = AppColors.inputBg; fg = AppColors.gray;
        icon = Icons.info_outline_rounded; label = status.toUpperCase().replaceAll('_', ' ');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

// ── Sita Chat Banner ──────────────────────────────────────────────────────────
class _SitaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SitaChatScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.20),
              child: const Text('🤖', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sita', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('LIVE EMERGENCY HELP',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No open cases nearby', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 6),
          Text('Check back soon or report one!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray)),
        ],
      ),
    );
  }
}

// ── Placeholder pages ─────────────────────────────────────────────────────────
class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌐', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Community', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.teal)),
              const SizedBox(height: 8),
              Text('Coming soon!', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray)),
            ],
          ),
        ),
      );
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.teal,
              child: Text(
                (auth.user?.name.isNotEmpty == true) ? auth.user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(auth.user?.name ?? 'User', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(auth.user?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, shape: const StadiumBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
