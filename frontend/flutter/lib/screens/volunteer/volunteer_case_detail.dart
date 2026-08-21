import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/case_model.dart';
import '../../providers/volunteer_provider.dart';
import '../../utils/app_colors.dart';
import 'pain_assessment_screen.dart';

/// Full case detail view for the volunteer — see triage info, navigate,
/// update case status step by step.
class VolunteerCaseDetail extends StatefulWidget {
  final CaseModel caseModel;
  const VolunteerCaseDetail({super.key, required this.caseModel});

  @override
  State<VolunteerCaseDetail> createState() => _VolunteerCaseDetailState();
}

class _VolunteerCaseDetailState extends State<VolunteerCaseDetail> {
  bool _updating = false;

  // Status flow for volunteers
  static const _statusFlow = [
    'reported',
    'assigned',
    'collected',
    'at_clinic',
    'in_treatment',
    'discharged',
  ];

  String? get _nextStatus {
    final cur = widget.caseModel.status?.toLowerCase() ?? 'reported';
    final idx = _statusFlow.indexOf(cur);
    if (idx == -1 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  String _statusLabel(String s) =>
      s.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');

  Future<void> _advance() async {
    final next = _nextStatus;
    if (next == null) return;
    setState(() => _updating = true);
    final ok = await context.read<VolunteerProvider>().advanceStatus(
          widget.caseModel.id!,
          next,
        );
    setState(() => _updating = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_statusLabel(next)}'),
          backgroundColor: AppColors.resolved,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  Future<void> _openMaps() async {
    final lat = widget.caseModel.latitude;
    final lon = widget.caseModel.longitude;
    if (lat == null || lon == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseModel;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        title: Text(
          c.title ?? 'Case #${c.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Severity + Status badges ──
            Row(
              children: [
                _badge(
                  c.severity ?? 'routine',
                  _severityColor(c.severity),
                  _severityBg(c.severity),
                ),
                const SizedBox(width: 8),
                _badge(
                  _statusLabel(c.status ?? 'reported'),
                  AppColors.teal,
                  AppColors.tealBg,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Image ──
            if ((c.imageUrl ?? c.imageDataUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  c.imageUrl ?? c.imageDataUrl ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: 0),
                ),
              ),
            if ((c.imageUrl ?? c.imageDataUrl ?? '').isNotEmpty)
              const SizedBox(height: 16),

            // ── Info cards ──
            _infoCard([
              _infoRow(Icons.pets, 'Species', c.species ?? 'Unknown'),
              _infoRow(Icons.medical_services, 'Injury', c.injuryType ?? 'Unknown'),
              _infoRow(Icons.location_on, 'Location', c.locationLabel ?? c.location ?? 'N/A'),
              if (c.latitude != null)
                _infoRow(Icons.gps_fixed, 'GPS',
                    '${c.latitude?.toStringAsFixed(5)}, ${c.longitude?.toStringAsFixed(5)}'),
            ]),
            const SizedBox(height: 12),

            // ── AI Triage result ──
            if ((c.probableCondition ?? '').isNotEmpty) ...[
              _sectionTitle('🤖 AI Triage Result'),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.probableCondition!,
                      style: const TextStyle(color: AppColors.dark, fontSize: 14),
                    ),
                    if ((c.firstAidSteps ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('First Aid Steps:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: AppColors.dark)),
                      const SizedBox(height: 4),
                      Text(
                        c.firstAidSteps!,
                        style:
                            const TextStyle(color: AppColors.gray, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Reporter info ──
            _sectionTitle('👤 Reporter'),
            _infoCard([
              _infoRow(Icons.person, 'Name', c.reporterName ?? 'Anonymous'),
              _infoRow(Icons.phone, 'Contact', c.reporterContact ?? 'N/A'),
            ]),
            const SizedBox(height: 12),

            // ── Status progress stepper ──
            _sectionTitle('📋 Status Progress'),
            _card(child: _StatusStepper(current: c.status ?? 'reported')),
            const SizedBox(height: 24),

            // ── Action buttons ──
            if (c.latitude != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate via Google Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _openMaps,
                ),
              ),
            if (c.latitude != null) const SizedBox(height: 12),

            // Clinical Pain Assessment Button (GCPS Vitals)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: const Text('Clinical Pain Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealBg,
                  foregroundColor: AppColors.teal,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PainAssessmentScreen(
                        breed: 'unknown_breed',
                        species: c.species ?? 'dog',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            if (_nextStatus != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _updating
                        ? 'Updating…'
                        : 'Mark as ${_statusLabel(_nextStatus!)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _updating ? null : _advance,
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _infoCard(List<Widget> rows) => _card(
        child: Column(
          children: rows
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: r,
                  ))
              .toList(),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.gray, fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(color: AppColors.dark, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _badge(String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      );

  Color _severityColor(String? s) {
    switch (s) {
      case 'critical': return AppColors.critical;
      case 'urgent': return AppColors.urgent;
      default: return AppColors.resolved;
    }
  }

  Color _severityBg(String? s) {
    switch (s) {
      case 'critical': return AppColors.criticalBg;
      case 'urgent': return AppColors.urgentBg;
      default: return AppColors.resolvedBg;
    }
  }
}

// ─── Status Stepper ──────────────────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final String current;

  const _StatusStepper({required this.current});

  static const _steps = [
    ('reported', '📋', 'Reported'),
    ('assigned', '👤', 'Assigned'),
    ('collected', '🚐', 'Collected'),
    ('at_clinic', '🏥', 'At Clinic'),
    ('in_treatment', '💉', 'In Treatment'),
    ('discharged', '✅', 'Discharged'),
  ];

  @override
  Widget build(BuildContext context) {
    final curIdx = _steps.indexWhere((s) => s.$1 == current.toLowerCase());
    return Column(
      children: _steps.asMap().entries.map((e) {
        final idx = e.key;
        final step = e.value;
        final done = idx < curIdx;
        final active = idx == curIdx;
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.resolved
                        : active
                            ? AppColors.teal
                            : AppColors.divider,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(step.$2,
                            style: const TextStyle(fontSize: 14)),
                  ),
                ),
                if (idx < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: done ? AppColors.resolved : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              step.$3,
              style: TextStyle(
                color: active
                    ? AppColors.teal
                    : done
                        ? AppColors.resolved
                        : AppColors.gray,
                fontWeight: active || done ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
