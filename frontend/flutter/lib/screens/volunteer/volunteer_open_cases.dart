import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../utils/app_colors.dart';
import 'volunteer_case_detail.dart';

/// Shows all open (REPORTED) cases — volunteers can pick up a case.
class VolunteerOpenCasesScreen extends StatefulWidget {
  const VolunteerOpenCasesScreen({super.key});
  @override
  State<VolunteerOpenCasesScreen> createState() => _VolunteerOpenCasesScreenState();
}

class _VolunteerOpenCasesScreenState extends State<VolunteerOpenCasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolunteerProvider>().loadOpenCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VolunteerProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        title: const Text('Open Cases Nearby',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vp.loadOpenCases,
          ),
        ],
      ),
      body: vp.loading
          ? const Center(child: CircularProgressIndicator())
          : vp.openCases.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 72, color: AppColors.resolved),
                      SizedBox(height: 16),
                      Text('No open cases right now!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                      SizedBox(height: 8),
                      Text('All animals are being cared for.',
                          style: TextStyle(color: AppColors.gray)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: vp.loadOpenCases,
                  color: AppColors.teal,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vp.openCases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final c = vp.openCases[i];
                      return _OpenCaseCard(
                        caseModel: c,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => VolunteerCaseDetail(caseModel: c)),
                        ).then((_) => vp.loadOpenCases()),
                        onAccept: () async {
                          final ok = await vp.acceptCase(c.id!);
                          if (ok && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Case accepted! Check My Cases.'),
                              backgroundColor: AppColors.resolved,
                            ));
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _OpenCaseCard extends StatelessWidget {
  final dynamic caseModel;
  final VoidCallback onTap;
  final VoidCallback onAccept;

  const _OpenCaseCard(
      {required this.caseModel, required this.onTap, required this.onAccept});

  String _emoji(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'cow': return '🐄';
      case 'bird': return '🐦';
      default: return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sev = caseModel.severity ?? 'routine';
    Color sevColor;
    Color sevBg;
    switch (sev) {
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: sevColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${_emoji(caseModel.species)} ',
                  style: const TextStyle(fontSize: 22)),
              Expanded(
                child: Text(
                  caseModel.title ?? caseModel.species ?? 'Animal',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.dark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: sevBg, borderRadius: BorderRadius.circular(20)),
                child: Text(sev.toUpperCase(),
                    style: TextStyle(
                        color: sevColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 6),
            if ((caseModel.locationLabel ?? '').isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on, size: 13, color: AppColors.gray),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(caseModel.locationLabel!,
                        style: const TextStyle(
                            color: AppColors.gray, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Accept'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
