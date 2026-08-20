import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().loadCases();
    });
  }

  String _emoji(String? species) {
    switch ((species ?? '').toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'cow': return '🐄';
      case 'bird': return '🐦';
      default: return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final casesProvider = context.watch<CaseProvider>();
    final cases = casesProvider.cases;

    final total = cases.length;
    final critical = cases.where((c) => c.severity == 'critical').length;
    final active = cases.where((c) => c.status != 'discharged' && c.status != 'adopted' && c.status != 'released').length;
    final discharged = cases.where((c) => c.status == 'discharged' || c.status == 'adopted' || c.status == 'released').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.menu, color: Colors.white),
            const SizedBox(width: 14),
            Text(
              'NGO Dashboard',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: casesProvider.loadCases,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats 2x2 grid
            Row(
              children: [
                // Total cases card in solid teal
                Expanded(
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL CASES',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$total',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(height: 3, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Critical cases white card
                Expanded(
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CRITICAL',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$critical',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.critical,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Urgent action',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.circle, size: 8, color: AppColors.critical),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Active cases card
                Expanded(
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$active',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'In progress',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Discharged cases card
                Expanded(
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISCHARGED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$discharged',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, size: 14, color: AppColors.resolved),
                            const SizedBox(width: 4),
                            Text(
                              '+4 today',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.resolved,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Live Cases Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.resolved),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE CASES',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Cases list
            if (cases.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No active cases right now.', style: TextStyle(color: AppColors.gray)),
                ),
              )
            else
              ...cases.take(3).map((c) {
                final sev = c.severity ?? 'routine';
                Color borderLeftColor;
                Color sevColor;
                Color sevBg;
                switch (sev.toLowerCase()) {
                  case 'critical':
                    borderLeftColor = AppColors.critical;
                    sevColor = AppColors.critical;
                    sevBg = AppColors.criticalBg;
                    break;
                  case 'urgent':
                    borderLeftColor = AppColors.urgent;
                    sevColor = AppColors.urgent;
                    sevBg = AppColors.urgentBg;
                    break;
                  default:
                    borderLeftColor = AppColors.gray;
                    sevColor = AppColors.resolved;
                    sevBg = AppColors.resolvedBg;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: borderLeftColor, width: 4),
                      top: const BorderSide(color: AppColors.divider),
                      right: const BorderSide(color: AppColors.divider),
                      bottom: const BorderSide(color: AppColors.divider),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_emoji(c.species)} ',
                              style: const TextStyle(fontSize: 22),
                            ),
                            Expanded(
                              child: Text(
                                c.title ?? c.species ?? 'Animal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.dark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sevBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sev.toUpperCase(),
                                style: TextStyle(
                                  color: sevColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.locationLabel ?? 'Location unknown',
                                style: GoogleFonts.inter(color: AppColors.gray, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned to: ${c.assignedResponder ?? "John D."}',
                              style: GoogleFonts.inter(
                                color: AppColors.dark.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  c.status == 'assigned'
                                      ? Icons.directions_car_filled_outlined
                                      : (c.status == 'collected' ? Icons.check_circle_outline : Icons.schedule),
                                  size: 14,
                                  color: AppColors.teal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (c.status == 'assigned'
                                          ? 'EN ROUTE'
                                          : (c.status == 'collected' ? 'ARRIVED' : 'PENDING'))
                                      .toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: AppColors.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Weekly Insights Section
            Text(
              'WEEKLY INSIGHTS',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // soft blue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '12% Faster Response',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Avg. 14 mins to reach spot this week.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF1E3A8A).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Small Circular progress visualization mockup
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 4,
                          color: const Color(0xFF1D4ED8),
                          backgroundColor: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const Icon(Icons.notifications_active, size: 18, color: Color(0xFF1D4ED8)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
