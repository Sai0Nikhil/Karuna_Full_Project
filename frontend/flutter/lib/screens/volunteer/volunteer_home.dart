import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/diamond_background.dart';
import 'volunteer_case_detail.dart';
import 'volunteer_open_cases.dart';

class VolunteerHome extends StatefulWidget {
  const VolunteerHome({super.key});

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolunteerProvider>().loadAssignedCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VolunteerProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: IndexedStack(
        index: _tab,
        children: const [_AssignedCasesTab(), VolunteerOpenCasesScreen()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // My Cases Tab
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _tab = 0);
                      vp.loadAssignedCases();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: _tab == 0 ? AppColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: _tab == 0 ? Colors.white : AppColors.gray,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Cases',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _tab == 0 ? AppColors.teal : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Open Cases Tab
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _tab = 1);
                      vp.loadOpenCases();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: _tab == 1 ? AppColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.explore_outlined,
                            color: _tab == 1 ? Colors.white : AppColors.gray,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open Cases',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _tab == 1 ? AppColors.teal : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignedCasesTab extends StatefulWidget {
  const _AssignedCasesTab();

  @override
  State<_AssignedCasesTab> createState() => _AssignedCasesTabState();
}

class _AssignedCasesTabState extends State<_AssignedCasesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolunteerProvider>().loadAssignedCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VolunteerProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Assigned Cases',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${vp.assignedCases.length} active cases pending',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Text('👩', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: LightDiamondBackground(
        child: vp.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : vp.assignedCases.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: vp.loadAssignedCases,
                    color: AppColors.teal,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vp.assignedCases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = vp.assignedCases[i];
                        return _VolunteerCaseCard(
                          caseModel: c,
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => VolunteerCaseDetail(caseModel: c),
                            ),
                          ).then((_) => vp.loadAssignedCases()),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_turned_in_outlined, size: 72, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            'No Assigned Cases',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When a case is dispatched to you, it will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.gray, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCaseCard extends StatelessWidget {
  final dynamic caseModel;
  final VoidCallback onTap;

  const _VolunteerCaseCard({required this.caseModel, required this.onTap});

  Color _severityColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'critical': return AppColors.critical;
      case 'urgent': return AppColors.urgent;
      default: return AppColors.resolved;
    }
  }

  Color _severityBg(String? s) {
    switch (s?.toLowerCase()) {
      case 'critical': return AppColors.criticalBg;
      case 'urgent': return AppColors.urgentBg;
      default: return AppColors.resolvedBg;
    }
  }

  String _speciesEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'cow': return '🐄';
      case 'bird': return '🐦';
      default: return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = caseModel.severity ?? 'routine';
    final status = caseModel.status ?? 'assigned';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and severity header line
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityBg(severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      color: _severityColor(severity),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // light blue
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Species emoji & title
            Row(
              children: [
                Text(
                  _speciesEmoji(caseModel.species ?? ''),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    caseModel.title ?? caseModel.species ?? 'Animal Case',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    caseModel.locationLabel ?? 'Location unknown',
                    style: GoogleFonts.inter(color: AppColors.gray, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Presets buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/map-routing',
                        arguments: {
                          'caseId': caseModel.id,
                          'caseLat': caseModel.latitude ?? 16.5,
                          'caseLon': caseModel.longitude ?? 80.6,
                          'animalTitle': caseModel.title ?? 'Animal',
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'NAVIGATE',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'VIEW DETAILS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
