import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/diamond_background.dart';

class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  String _filter = 'ALL';

  final _filters = ['ALL', 'REPORTED', 'ASSIGNED', 'IN TREATMENT', 'DISCHARGED'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchMyCases();
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
    final casesProvider = context.watch<CaseProvider>();
    final allMyCases = casesProvider.myCases;

    final filtered = allMyCases.where((c) {
      if (_filter == 'ALL') return true;
      final status = (c.status ?? '').toUpperCase().replaceAll('_', ' ');
      return status == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.dark),
            const SizedBox(width: 14),
            Text(
              'My Cases',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.teal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF115E59),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tealLight,
              child: const Text('👨', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: LightDiamondBackground(
        child: Column(
          children: [
            // Scrollable filter chips row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final item = _filters[idx];
                    final active = _filter == item;
                    return ChoiceChip(
                      label: Text(item),
                      selected: active,
                      selectedColor: AppColors.teal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.dark,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: active ? AppColors.teal : AppColors.divider,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _filter = item);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Cases list
            Expanded(
              child: casesProvider.loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🐾', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'No cases found',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap Report to help an animal in need',
                                style: GoogleFonts.inter(color: AppColors.gray),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.teal,
                          onRefresh: () => context.read<CaseProvider>().fetchMyCases(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final c = filtered[i];
                              final sev = c.severity ?? 'routine';
                              Color sevColor;
                              Color sevBg;
                              switch (sev.toLowerCase()) {
                                case 'critical':
                                  sevColor = AppColors.critical;
                                  sevBg = AppColors.criticalBg;
                                  break;
                                case 'urgent':
                                  sevColor = AppColors.urgent;
                                  sevBg = AppColors.urgentBg;
                                  break;
                                default:
                                  sevColor = AppColors.resolved;
                                  sevBg = AppColors.resolvedBg;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                  border: Border.all(
                                    color: AppColors.divider,
                                    width: 1.0,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/citizen/case',
                                    arguments: c.id,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Species large emoji inside colored container
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: AppColors.tealLight.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _emoji(c.species),
                                              style: const TextStyle(fontSize: 28),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Central info block
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      c.title ?? c.species ?? 'Animal Case',
                                                      style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: AppColors.dark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
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
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 13,
                                                    color: AppColors.gray,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      c.locationLabel ?? 'Location unknown',
                                                      style: GoogleFonts.inter(
                                                        color: AppColors.gray,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),

                                              // Status dot pill
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.tealLight.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.circle,
                                                          size: 8,
                                                          color: AppColors.teal,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          (c.status ?? 'reported').toUpperCase().replaceAll('_', ' '),
                                                          style: GoogleFonts.inter(
                                                            color: AppColors.teal,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  // Date text at bottom
                                                  Text(
                                                    'Reported: 12 Oct',
                                                    style: GoogleFonts.inter(
                                                      color: AppColors.gray,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Arrow circle button
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.tealLight.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                              color: AppColors.teal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
