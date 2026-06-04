import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';

/// First Aid Screen – powered by Gemini AI
/// Accessible without login from the home screen
class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  String? _species;
  final _injuryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  FirstAidResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _injuryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getFirstAid() async {
    if (_injuryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the situation')),
      );
      return;
    }
    setState(() { _loading = true; _result = null; });
    final result = await AiService.getFirstAid(
      species: _species ?? 'animal',
      injuryDescription: _injuryCtrl.text.trim(),
      locationContext: _locationCtrl.text.trim(),
    );
    setState(() { _loading = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(children: [
          Text('🤖 ', style: TextStyle(fontSize: 18)),
          Text('AI First Aid', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text('🐾', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Gemini AI First Aid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.teal)),
                      SizedBox(height: 2),
                      Text('Get instant first aid guidance while waiting for rescue.',
                          style: TextStyle(fontSize: 12, color: AppColors.tealDark)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Animal type
            const Text('Animal Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10, runSpacing: 8,
              children: [
                ['dog', '🐕 Dog'], ['cat', '🐈 Cat'], ['cow', '🐄 Cow'],
                ['bird', '🦜 Bird'], ['other', '❓ Other'],
              ].map((s) {
                final active = _species == s[0];
                return GestureDetector(
                  onTap: () => setState(() => _species = s[0]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.teal : AppColors.lightGray),
                    ),
                    child: Text(s[1],
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.dark,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Injury description
            const Text('Describe the Situation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 8),
            TextField(
              controller: _injuryCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. "Dog is limping badly, front leg seems broken, found on road, breathing fast..."',
              ),
            ),
            const SizedBox(height: 16),

            // Location context
            const Text('Location (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. near a busy road, in a park...',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.gray),
              ),
            ),
            const SizedBox(height: 24),

            LoadingButton(
              label: '🤖 Get AI First Aid',
              loading: _loading,
              onPressed: _getFirstAid,
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              const Text('🤖 Gemini AI Response', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.teal)),
              const SizedBox(height: 16),

              // Immediate steps
              if (_result!.immediateSteps.isNotEmpty) ...[
                _sectionCard(
                  '✅ Do This Right Now',
                  AppColors.resolvedBg,
                  AppColors.resolved,
                  Column(
                    children: _result!.immediateSteps.asMap().entries.map((e) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(color: AppColors.resolved, shape: BoxShape.circle),
                              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.4))),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Do NOT do
              if (_result!.doNotDo.isNotEmpty) ...[
                _sectionCard(
                  '⚠️ Do NOT Do This',
                  AppColors.criticalBg,
                  AppColors.critical,
                  Column(
                    children: _result!.doNotDo.map((w) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✗ ', style: TextStyle(color: AppColors.critical, fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(w, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.4))),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // When to call vet
              if (_result!.whenToCallVet != null)
                _sectionCard(
                  '📞 When to Call for Help',
                  AppColors.urgentBg,
                  AppColors.urgent,
                  Text(_result!.whenToCallVet!, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
                ),

              const SizedBox(height: 16),
              const Text(
                '⚠️ This is AI-generated guidance. Always contact a professional vet or rescue NGO.',
                style: TextStyle(fontSize: 11, color: AppColors.gray, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, Color bgColor, Color borderColor, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: borderColor)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}
