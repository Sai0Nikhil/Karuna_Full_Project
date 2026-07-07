import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'report_flow.dart';
import 'donate_screen.dart';
import 'adopt_screen.dart';
import 'my_cases_screen.dart';
import 'sita_chat_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});
  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _tab = 0;
  final List<Widget> _pages = const [
    _HomeTab(), ReportFlow(), DonateScreen(), AdoptScreen(), MyCasesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _KarunaBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          _NavItem(icon: '⌂', label: 'Home'),
          _NavItem(icon: '◈', label: 'Report'),
          _NavItem(icon: '♡', label: 'Donate'),
          _NavItem(icon: '⚘', label: 'Adopt'),
          _NavItem(icon: '☰', label: 'My Cases'),
        ],
      ),
    );
  }
}

// ── Figma-accurate bottom nav: solid teal bg, white icons ─────────────────────
class _KarunaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  const _KarunaBottomNav({required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
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
                      Text(item.icon,
                          style: TextStyle(
                            fontSize: 22,
                            color: active ? Colors.white : Colors.white54,
                          )),
                      const SizedBox(height: 2),
                      Text(item.label,
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

class _NavItem {
  final String icon, label;
  const _NavItem({required this.icon, required this.label});
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
    final name = auth.user?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => context.read<CaseProvider>().fetchOpenCases(),
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  const Text('Karuna',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.teal)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.gray),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: AppColors.gray),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
                    child: Text('Hi, $name 👋',
                        style: const TextStyle(fontSize: 16, color: AppColors.gray)),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                child: const Divider(height: 1, color: AppColors.divider),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero banner ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 128,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20, top: -20,
                          child: Container(
                            width: 180, height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Report an Animal in Need',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Connect stray & injured animals\nwith care & rescue teams',
                                  style: TextStyle(color: Color(0xFFDDF3F2), fontSize: 11)),
                              const SizedBox(height: 10),
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: const Center(
                                  child: Text('Report Now',
                                      style: TextStyle(color: AppColors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats ────────────────────────────────────────────────
                  const Text("This Month's Impact",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard('248', 'Reports'),
                      const SizedBox(width: 10),
                      _statCard('89', 'Rescued'),
                      const SizedBox(width: 10),
                      _statCard('124', 'Adopted'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Actions ────────────────────────────────────────
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAction('💝', 'Donate', () => Navigator.pushNamed(context, '/citizen/donate')),
                      _quickAction('🐾', 'Adopt', () => Navigator.pushNamed(context, '/citizen/adopt')),
                      _quickAction('📁', 'My Reports', () => Navigator.pushNamed(context, '/citizen/cases')),
                      _quickAction('🤖', 'AI First Aid',
                          () => Navigator.pushNamed(context, '/citizen/firstaid')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Talk to Sita ─────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const SitaChatScreen(),
                    )),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Talk to Sita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('AI animal rescue guide — ask anything', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        )),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Recent Reports ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Reports',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text('See all',
                            style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Case list
                  if (caseProvider.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.teal)))
                  else
                    ...caseProvider.openCases.take(5).map((c) => _FigmaCaseCard(
                          title: '${c.speciesEmoji} ${c.species ?? 'Animal'}',
                          subtitle: c.locationLabel ?? 'Unknown location',
                          caseId: '#K${c.id.toString().padLeft(3, '0')}',
                          status: c.severity ?? c.status ?? 'reported',
                          onTap: () => Navigator.pushNamed(context, '/citizen/case', arguments: c.id),
                        )),

                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.teal)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78, height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.dark, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Figma-style case card: white + teal border ────────────────────────────────
class _FigmaCaseCard extends StatelessWidget {
  final String title, subtitle, caseId, status;
  final VoidCallback onTap;
  const _FigmaCaseCard({
    required this.title, required this.subtitle,
    required this.caseId, required this.status, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Photo placeholder
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.tealBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal, width: 1),
              ),
              child: Center(child: Text(title.split(' ').first, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.replaceFirst(title.split(' ').first, '').trim(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  const SizedBox(height: 2),
                  Text(caseId, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                ],
              ),
            ),
            StatusBadge(status),
          ],
        ),
      ),
    );
  }
}
