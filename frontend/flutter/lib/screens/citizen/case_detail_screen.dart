import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../services/adoption_service.dart';
import '../../models/adoption_model.dart';
import '../../utils/pdf_ledger_helper.dart';
import '../../widgets/loading_button.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  List<AdoptionModel> _applications = [];
  bool _loadingAdoptions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchCase(widget.caseId);
      _loadAdoptions();
    });
  }

  Future<void> _loadAdoptions() async {
    setState(() => _loadingAdoptions = true);
    try {
      final list = await AdoptionService.getAdoptionsForCase(widget.caseId);
      setState(() {
        _applications = list;
        _loadingAdoptions = false;
      });
    } catch (_) {
      setState(() => _loadingAdoptions = false);
    }
  }

  void _showCheckinDialog(AdoptionModel app) {
    final textCtrl = TextEditingController();
    String? photoUrl;
    bool photoAttached = false;
    bool subLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit Pet Check-in Report',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
              const SizedBox(height: 6),
              const Text('Share updates on pet recovery, diet, and behavior with the NGO.',
                  style: TextStyle(fontSize: 12, color: AppColors.gray)),
              const Divider(height: 24),
              TextFormField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Status Details',
                  hintText: 'How is the animal adjusting to its new home?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    photoAttached ? '✓ Photo attached' : 'No photo attached',
                    style: TextStyle(fontSize: 12, color: photoAttached ? Colors.green[700] : AppColors.gray, fontWeight: photoAttached ? FontWeight.bold : FontWeight.normal),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final petPhotos = [
                        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150', // Happy dog
                        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=150', // Happy cat
                        'https://images.unsplash.com/photo-1552053831-71594a27632d?w=150'  // Golden retriever
                      ];
                      setSheetState(() {
                        photoAttached = true;
                        photoUrl = petPhotos[DateTime.now().millisecond % petPhotos.length];
                      });
                    },
                    icon: const Icon(Icons.camera_alt, size: 14),
                    label: const Text('Capture photo', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Submit Check-in',
                loading: subLoading,
                onPressed: () async {
                  if (textCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter status details')),
                    );
                    return;
                  }
                  setSheetState(() => subLoading = true);
                  try {
                    await AdoptionService.addCheckin(
                      appId: app.id,
                      text: textCtrl.text.trim(),
                      photoUrl: photoUrl,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Check-in submitted successfully!'), backgroundColor: AppColors.teal),
                    );
                    _loadAdoptions(); // Reload check-ins list
                  } catch (e) {
                    setSheetState(() => subLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.critical),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
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

                  // Download PDF Ledger card
                  _sectionTitle('Audit & Transparency Ledger'),
                  _card(
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.teal, size: 36),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Transaction & Treatment Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Download full audit log of expenses & donations', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: AppColors.teal),
                          onPressed: () => PdfLedgerHelper.generateAndPrintLedger(c),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Post-Placement Check-ins section
                  (() {
                    if (_applications.isEmpty) return const SizedBox.shrink();
                    final approvedApps = _applications.where((a) => a.status?.toLowerCase() == 'approved').toList();
                    if (approvedApps.isEmpty) return const SizedBox.shrink();
                    final app = approvedApps.first;

                    // Parse logs
                    List<dynamic> logs = [];
                    if (app.checkinsLogs != null && app.checkinsLogs!.isNotEmpty && app.checkinsLogs != '[]') {
                      try {
                        logs = jsonDecode(app.checkinsLogs!);
                      } catch (_) {}
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Post-Placement Check-ins 🏡'),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Approved Adopter: ${app.applicantName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        const Text('Mandatory post-placement follow-up logs', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showCheckinDialog(app),
                                    icon: const Icon(Icons.add_home, size: 14),
                                    label: const Text('Add Check-in', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                  ),
                                ],
                              ),
                              if (logs.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: logs.length,
                                  itemBuilder: (ctx, index) {
                                    final log = logs[logs.length - 1 - index];
                                    final date = log['date'] != null ? DateTime.tryParse(log['date'])?.toLocal() : null;
                                    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : 'Recent';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('🟢', style: TextStyle(fontSize: 10)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                                                    if (log['photoUrl'] != null && log['photoUrl'].toString().isNotEmpty)
                                                      const Text('📸 Photo attached', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(log['text'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                if (log['photoUrl'] != null && log['photoUrl'].toString().isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      log['photoUrl'],
                                                      width: 120,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  })(),
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
