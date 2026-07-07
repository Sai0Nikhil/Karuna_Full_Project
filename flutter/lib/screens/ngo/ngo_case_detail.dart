import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_button.dart';

class NgoCaseDetail extends StatefulWidget {
  final int caseId;
  const NgoCaseDetail({super.key, required this.caseId});

  @override
  State<NgoCaseDetail> createState() => _NgoCaseDetailState();
}

class _NgoCaseDetailState extends State<NgoCaseDetail> {
  final _noteCtrl = TextEditingController();
  final _responderCtrl = TextEditingController();
  bool _addingNote = false;
  bool _assigning = false;
  String? _selectedStatus;
  CaseSummaryResult? _aiSummary;
  bool _loadingSummary = false;

  // Status flow matching backend enum
  final List<(String, String, String)> _statuses = [
    ('reported', '📋 Reported', 'Case registered'),
    ('assigned', '👤 Assigned', 'Team assigned'),
    ('collected', '🚑 Collected', 'Animal collected'),
    ('at_clinic', '🏥 At Clinic', 'Arrived at clinic'),
    ('in_treatment', '💉 Treating', 'Under treatment'),
    ('discharged', '✅ Discharged', 'Treatment complete'),
    ('adopted', '🐾 Adopted', 'Found a home'),
    ('released', '🌿 Released', 'Released to wild'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchCase(widget.caseId);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose(); _responderCtrl.dispose();
    super.dispose();
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Critical banner
            if (c.isCritical)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.criticalBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('🆘', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('CRITICAL – Immediate Action Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.critical, fontSize: 13)),
                        Text('${c.species ?? 'Animal'} · ${c.locationLabel ?? ''}', style: const TextStyle(color: AppColors.critical, fontSize: 11)),
                      ]),
                    ),
                  ],
                ),
              ),
            if (c.isCritical) const SizedBox(height: 12),

            // Animal summary
            _card(
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(c.speciesEmoji, style: const TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${c.species ?? 'Animal'} · ${c.injuryType ?? ''}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      const SizedBox(height: 4),
                      StatusBadge(c.severity ?? 'routine'),
                      const SizedBox(height: 4),
                      Text('📍 ${c.locationLabel ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      Text('👤 Reported by ${c.reporterName}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      if (c.latitude != null && c.longitude != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/map-routing',
                              arguments: {
                                'caseId': c.id,
                                'caseLat': c.latitude,
                                'caseLon': c.longitude,
                                'animalTitle': '${c.species ?? "Animal"} (${c.injuryType ?? "Injured"})',
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation_outlined, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Navigate to Case 🚑', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── AI Summary Card ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('🤖 AI Summary', inline: true),
                TextButton.icon(
                  onPressed: _loadingSummary ? null : () async {
                    setState(() => _loadingSummary = true);
                    final summary = await AiService.getCaseSummary(c.id);
                    setState(() { _aiSummary = summary; _loadingSummary = false; });
                  },
                  icon: _loadingSummary
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                      : const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal),
                  label: Text(_loadingSummary ? 'Analyzing...' : 'Generate', style: const TextStyle(color: AppColors.teal, fontSize: 12)),
                ),
              ],
            ),
            if (_aiSummary != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_aiSummary!.headline != null)
                    Text(_aiSummary!.headline!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.teal)),
                  if (_aiSummary!.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(_aiSummary!.summary!, style: const TextStyle(fontSize: 12, color: AppColors.dark, height: 1.5)),
                  ],
                  if (_aiSummary!.recommendedNextStep != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_forward, size: 14, color: AppColors.teal),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Next: ${_aiSummary!.recommendedNextStep}',
                              style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            const SizedBox(height: 12),

            // Current status
            _sectionTitle('Current Status'),
            _card(StatusBadge(c.status ?? 'reported')),
            const SizedBox(height: 12),

            // Assign volunteer
            _sectionTitle('Assign / Update Responder'),
            _card(
              Column(
                children: [
                  TextField(
                    controller: _responderCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter responder / volunteer name',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LoadingButton(
                    label: 'Assign Responder',
                    loading: _assigning,
                    onPressed: () async {
                      if (_responderCtrl.text.trim().isEmpty) return;
                      setState(() => _assigning = true);
                      await cases.advanceStatus(c.id, 'assigned');
                      setState(() => _assigning = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Responder assigned!'), backgroundColor: AppColors.teal),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Advance status
            _sectionTitle('Update Case Status'),
            _card(
              Column(
                children: _statuses.map((s) {
                  final isCurrentStatus = c.status == s.$1;
                  final statusIndex = _statuses.indexWhere((x) => x.$1 == c.status);
                  final thisIndex = _statuses.indexWhere((x) => x.$1 == s.$1);
                  final isPast = thisIndex < statusIndex;
                  final isSelected = _selectedStatus == s.$1;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedStatus = s.$1),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentStatus ? AppColors.tealLight
                            : isSelected ? AppColors.inputBg : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentStatus ? AppColors.teal
                              : isSelected ? AppColors.teal : AppColors.lightGray,
                          width: isCurrentStatus || isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrentStatus ? AppColors.teal : isPast ? AppColors.resolved : AppColors.lightGray,
                            ),
                            child: Center(
                              child: Icon(
                                isCurrentStatus ? Icons.radio_button_checked : isPast ? Icons.check : Icons.radio_button_unchecked,
                                size: 14, color: isCurrentStatus || isPast ? Colors.white : AppColors.gray,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.$2, style: TextStyle(fontSize: 13, fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal, color: isCurrentStatus ? AppColors.teal : AppColors.dark)),
                              Text(s.$3, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                            ]),
                          ),
                          if (isCurrentStatus) const Text('← Current', style: TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedStatus != null && _selectedStatus != c.status) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await cases.advanceStatus(c.id, _selectedStatus!);
                  setState(() => _selectedStatus = null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status updated!'), backgroundColor: AppColors.teal),
                    );
                  }
                },
                child: Text('Set to "${_statuses.firstWhere((s) => s.$1 == _selectedStatus).$2}"'),
              ),
            ],
            const SizedBox(height: 12),

            // Add note
            _sectionTitle('Add Field Note'),
            _card(
              Column(
                children: [
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Add an update note about this case...'),
                  ),
                  const SizedBox(height: 10),
                  LoadingButton(
                    label: 'Save Note',
                    loading: _addingNote,
                    onPressed: () async {
                      if (_noteCtrl.text.trim().isEmpty) return;
                      setState(() => _addingNote = true);
                      await cases.addNote(c.id, _noteCtrl.text.trim());
                      _noteCtrl.clear();
                      setState(() => _addingNote = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note saved!'), backgroundColor: AppColors.teal),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
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

  Widget _sectionTitle(String title, {bool inline = false}) {
    final widget = Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark));
    if (inline) return widget;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: widget);
  }
}
