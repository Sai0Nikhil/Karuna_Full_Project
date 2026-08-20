import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';

/// NGO Analytics screen — shows summary statistics from the loaded cases.
class NgoAnalyticsScreen extends StatelessWidget {
  const NgoAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CaseProvider>();
    final cases = cp.cases;

    final total = cases.length;
    final critical = cases.where((c) => c.severity == 'critical').length;
    final urgent = cases.where((c) => c.severity == 'urgent').length;
    final routine = cases.where((c) => c.severity == 'routine').length;
    final assigned = cases.where((c) => c.status == 'assigned').length;
    final discharged = cases.where((c) => c.status == 'discharged').length;

    // Species distribution
    final speciesCounts = <String, int>{};
    for (final c in cases) {
      final sp = c.species ?? 'unknown';
      speciesCounts[sp] = (speciesCounts[sp] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: cp.loadCases,
        color: AppColors.teal,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overview row ──
            Row(children: [
              _StatCard(label: 'Total Cases', value: '$total', color: AppColors.teal),
              const SizedBox(width: 12),
              _StatCard(label: 'Discharged', value: '$discharged', color: AppColors.resolved),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(label: 'Critical', value: '$critical', color: AppColors.critical),
              const SizedBox(width: 12),
              _StatCard(label: 'Urgent', value: '$urgent', color: AppColors.urgent),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(label: 'Routine', value: '$routine', color: AppColors.gray),
              const SizedBox(width: 12),
              _StatCard(label: 'Active (Assigned)', value: '$assigned', color: AppColors.active),
            ]),
            const SizedBox(height: 24),

            // ── Species breakdown ──
            const Text('Species Breakdown',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 12),
            if (speciesCounts.isEmpty)
              const Center(
                  child: Text('No data yet.', style: TextStyle(color: AppColors.gray))),
            ...speciesCounts.entries.map((e) {
              final pct = total == 0 ? 0.0 : e.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        '${_speciesEmoji(e.key)} ${e.key[0].toUpperCase()}${e.key.substring(1)}',
                        style: const TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: AppColors.gray, fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.divider,
                        color: AppColors.teal,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _speciesEmoji(String s) {
    switch (s.toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'cow': return '🐄';
      case 'bird': return '🐦';
      case 'monkey': return '🐒';
      default: return '🐾';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }
}
