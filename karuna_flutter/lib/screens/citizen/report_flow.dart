import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';

class ReportFlow extends StatefulWidget {
  const ReportFlow({super.key});

  @override
  State<ReportFlow> createState() => _ReportFlowState();
}

class _ReportFlowState extends State<ReportFlow> {
  int _step = 0;

  // Step 1 data
  String? _species;
  String? _injuryType;
  String? _severity;
  final _descCtrl = TextEditingController();

  // Step 2 data
  final _locationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cases = context.read<CaseProvider>();
    final result = await cases.createCase(
      reporterName: auth.user?.name ?? 'Anonymous',
      reporterContact: auth.user?.email,
      species: _species,
      injuryType: _injuryType,
      severity: _severity,
      locationLabel: '${_locationCtrl.text}, ${_cityCtrl.text}',
      probableCondition: _descCtrl.text.isEmpty ? null : _descCtrl.text,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _step = 2); // success step
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cases.error ?? 'Failed to submit'), backgroundColor: AppColors.critical),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Animal'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
      ),
      body: Column(
        children: [
          // Progress bar
          if (_step < 2) _buildProgress(),
          Expanded(
            child: _step == 0
                ? _buildStep1()
                : _step == 1
                    ? _buildStep2()
                    : _buildSuccess(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step ${_step + 1} of 2', style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / 2,
              backgroundColor: AppColors.lightGray,
              color: AppColors.teal,
              minHeight: 5,
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What did you find?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 4),
          const Text('Select the animal and its condition', style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 20),

          // Animal type
          const Text('Animal Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ['dog', '🐕', 'Dog'], ['cat', '🐈', 'Cat'],
              ['cow', '🐄', 'Cow'], ['bird', '🦜', 'Bird'], ['other', '❓', 'Other'],
            ].map((s) => _selectorChip(s[0], s[1], s[2], _species, (v) => setState(() => _species = v))).toList(),
          ),
          const SizedBox(height: 20),

          // Condition
          const Text('Condition / Injury', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ['critical', '🆘', 'Critical'], ['urgent', '🚑', 'Injured'],
              ['sick', '😟', 'Sick'], ['stray', '🐾', 'Stray'],
            ].map((s) => _selectorChip(s[0], s[1], s[2], _injuryType, (v) => setState(() => _injuryType = v))).toList(),
          ),
          const SizedBox(height: 20),

          // Severity
          const Text('Urgency Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 10),
          Row(children: [
            ['critical', '🔴 Critical'],
            ['urgent', '🟡 Urgent'],
            ['routine', '🟢 Routine'],
          ].map((s) => Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _selectorChip(s[0], '', s[1], _severity, (v) => setState(() => _severity = v)),
          ))).toList()),
          const SizedBox(height: 20),

          // Description
          const Text('Description (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe the animal\'s situation in detail...',
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Next: Add Location →'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final cases = context.watch<CaseProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where is the animal?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 4),
          const Text('Help rescuers find the location quickly', style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 20),

          // Map placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFDDEAF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text('Map view coming soon', style: TextStyle(color: AppColors.gray, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.my_location, color: AppColors.teal, size: 16),
                  label: const Text('Use My Location', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Street / Landmark',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.gray),
              hintText: 'e.g. Near City Park, MG Road',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityCtrl,
            decoration: const InputDecoration(
              labelText: 'City / Area',
              prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.gray),
              hintText: 'e.g. Koramangala, Bangalore',
            ),
          ),
          const SizedBox(height: 14),

          // Photo (placeholder)
          const Text('Add Photos (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 10),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.lightGray)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.teal, size: 22),
                      SizedBox(height: 2),
                      Text('Add', style: TextStyle(fontSize: 9, color: AppColors.teal)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Tap to attach photos\nfrom your gallery', style: TextStyle(color: AppColors.gray, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          LoadingButton(label: 'Submit Report 🐾', loading: cases.loading, onPressed: _submit),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('← Back', style: TextStyle(color: AppColors.gray)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.resolvedBg, borderRadius: BorderRadius.circular(50)),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 24),
            const Text('Report Submitted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            const Text('Your report has been received. A rescue NGO will be assigned and you\'ll receive updates.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.gray)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Report Another'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/citizen/cases'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View My Cases'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorChip(String value, String emoji, String label, String? selected, void Function(String) onSelect) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.tealLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.teal : AppColors.lightGray, width: active ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (emoji.isNotEmpty) ...[Text(emoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: active ? AppColors.teal : AppColors.dark, fontWeight: active ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
        ]),
      ),
    );
  }
}
