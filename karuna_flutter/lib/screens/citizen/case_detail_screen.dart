import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchCase(widget.caseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>();
    final c = cases.selectedCase;

    if (cases.loading || c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.teal)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Case #K${c.id.toString().padLeft(3, '0')}'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              height: 180,
              color: AppColors.tealLight,
              child: Stack(
                children: [
                  Center(child: Text(c.speciesEmoji, style: const TextStyle(fontSize: 90))),
                  if (c.isCritical)
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(14)),
                        child: const Text('🆘 Critical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Current Status', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                          const SizedBox(height: 4),
                          StatusBadge(c.status ?? 'reported'),
                        ]),
                        if (c.isAssigned) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Assigned to', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                          const SizedBox(height: 4),
                          Text(c.assignedResponder ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                          if (c.ngo != null) Text(c.ngo!, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Animal details
                  _sectionTitle('Animal Details'),
                  _card(
                    child: Column(
                      children: [
                        _detailRow('Type', '${c.speciesEmoji} ${c.species ?? 'Unknown'}'),
                        _detailRow('Condition', c.injuryType ?? 'Not specified'),
                        _detailRow('Severity', c.severity ?? 'Not specified'),
                        _detailRow('Location', c.locationLabel ?? 'Unknown'),
                        _detailRow('Reported by', c.reporterName),
                        if (c.probableCondition != null && c.probableCondition!.isNotEmpty)
                          _detailRow('Notes', c.probableCondition!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // First aid tips (if any)
                  if (c.firstAidSteps != null && c.firstAidSteps!.length > 2) ...[
                    _sectionTitle('First Aid Tips'),
                    _card(
                      child: Text(c.firstAidSteps!.replaceAll('[', '').replaceAll(']', '').replaceAll('"', ''),
                          style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Estimated cost
                  if (c.estimatedCostInr != null) ...[
                    _sectionTitle('Estimated Treatment Cost'),
                    _card(
                      child: Row(
                        children: [
                          const Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.teal)),
                          const SizedBox(width: 4),
                          Text('${c.estimatedCostInr}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.teal)),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/citizen/donate'),
                            icon: const Icon(Icons.favorite, size: 16),
                            label: const Text('Donate'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
    );
  }

  Widget _detailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(key, style: const TextStyle(fontSize: 12, color: AppColors.gray))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.dark))),
        ],
      ),
    );
  }
}
