import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';

/// Vet Tracking – track treatment progress of cases
/// Matches Figma "vet tracking" screen
class VetTrackingScreen extends StatelessWidget {
  const VetTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>();
    final activeCases = cases.allCases.where((c) => !c.isResolved).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Treatment Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF0D5C56)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Treatment Progress', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _progressStat('${activeCases.length}', 'In Treatment', Colors.white),
                      const SizedBox(width: 20),
                      _progressStat('${cases.allCases.where((c) => c.isResolved).length}', 'Recovered', Colors.white),
                      const SizedBox(width: 20),
                      _progressStat('3', 'Critical', const Color(0xFFFFCDD2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active treatments
            const Text('Active Treatments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            if (cases.loading)
              const Center(child: CircularProgressIndicator(color: AppColors.teal))
            else
              ...activeCases.take(6).map((c) => _TrackingCard(
                    emoji: c.speciesEmoji,
                    title: '${c.species ?? 'Animal'} – ${c.injuryType ?? 'Treatment'}',
                    stage: c.status ?? 'reported',
                    location: c.locationLabel ?? '',
                    caseId: '#K${c.id.toString().padLeft(3, '0')}',
                  )),

            if (activeCases.isEmpty) ...[
              // Demo cards
              const _TrackingCard(emoji: '🐕', title: 'Labrador – Fracture treatment', stage: 'in_treatment', location: 'Koramangala', caseId: '#K001'),
              const _TrackingCard(emoji: '🐈', title: 'Persian Cat – Post surgery', stage: 'at_clinic', location: 'HSR Layout', caseId: '#K002'),
              const _TrackingCard(emoji: '🦜', title: 'Parrot – Wing injury', stage: 'assigned', location: 'Indiranagar', caseId: '#K005'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressStat(String value, String label, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8))),
      ],
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final String emoji, title, stage, location, caseId;
  const _TrackingCard({required this.emoji, required this.title, required this.stage, required this.location, required this.caseId});

  @override
  Widget build(BuildContext context) {
    // Treatment stages for progress indicator
    const stages = ['reported', 'assigned', 'collected', 'at_clinic', 'in_treatment', 'discharged'];
    final stageIndex = stages.indexOf(stage).clamp(0, stages.length - 1);
    final progress = (stageIndex + 1) / stages.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                    const SizedBox(height: 2),
                    Text('$caseId · $location', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                ),
              ),
              StatusBadge(stage),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              const Text('Progress', style: TextStyle(fontSize: 10, color: AppColors.gray)),
              const Spacer(),
              Text('Stage ${stageIndex + 1}/${stages.length}', style: const TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              color: AppColors.teal,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
