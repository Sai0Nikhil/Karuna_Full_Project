import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';

/// Vet Clinic Profile/Info screen – includes FDA Veterinary Drug adverse reaction search
class VetClinicScreen extends StatelessWidget {
  const VetClinicScreen({super.key});

  void _showDrugSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _DrugSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinic Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.gray),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Clinic header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(40)),
                    child: const Center(child: Text('🏥', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 12),
                  const Text('PawCare Veterinary Clinic',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 4),
                  Text('Dr. ${auth.user?.name ?? 'Neha Sharma'}',
                      style: const TextStyle(fontSize: 14, color: AppColors.teal, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Koramangala, Bangalore · VCNO-2024-1245',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge('✅ Verified', AppColors.resolvedBg, AppColors.resolved),
                      const SizedBox(width: 8),
                      _badge('⭐ 4.8 Rating', AppColors.urgentBg, AppColors.urgent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FDA Drug Search Utility
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search_outlined, color: Colors.white),
                label: const Text('Search Vet Medicines (FDA Database)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showDrugSearchDialog(context),
              ),
            ),

            // Info sections
            _infoCard('Clinic Details', [
              const _InfoRow(Icons.location_on_outlined, 'Address', '12, 3rd Cross, Koramangala, Bangalore - 560034'),
              const _InfoRow(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
              const _InfoRow(Icons.email_outlined, 'Email', 'pawcare@vetclinic.in'),
              const _InfoRow(Icons.access_time_outlined, 'Hours', 'Mon–Sat: 9AM – 6PM'),
            ]),
            const SizedBox(height: 12),

            _infoCard('Specialisations', [
              const _InfoRow(Icons.pets, 'Species', 'Dogs, Cats, Birds, Rabbits'),
              const _InfoRow(Icons.medical_services_outlined, 'Services', 'Surgery, Vaccination, Emergency Care'),
              const _InfoRow(Icons.science_outlined, 'Lab', 'In-house diagnostics available'),
            ]),
            const SizedBox(height: 12),

            // Emergency toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_outlined, color: AppColors.critical),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Emergency Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
                      Text('Accept emergency cases from NGOs', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                    ]),
                  ),
                  Switch(value: true, onChanged: (_) {}, activeColor: AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoCard(String title, List<_InfoRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.icon, size: 16, color: AppColors.teal),
                    const SizedBox(width: 10),
                    SizedBox(width: 80, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.gray))),
                    Expanded(child: Text(r.value, style: const TextStyle(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
}

/// Dynamic Bottom Sheet to Search FDA Veterinary Drugs
class _DrugSearchSheet extends StatefulWidget {
  const _DrugSearchSheet();
  @override
  State<_DrugSearchSheet> createState() => _DrugSearchSheetState();
}

class _DrugSearchSheetState extends State<_DrugSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _drugs = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _drugs = [];
    });

    try {
      final response = await ApiService.get('/veterinarians/drugs?query=$q');
      setState(() {
        _drugs = response as List<dynamic>;
        _loading = false;
        if (_drugs.isEmpty) {
          _error = 'No matching FDA animal drugs found.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load FDA database: ${e.toString()}';
        _loading = false;
      });
    }
  }

  List<String> _getAdministrationTips(String dosageForm, String route) {
    final d = dosageForm.toLowerCase();
    final r = route.toLowerCase();

    if (d.contains('tablet') || d.contains('capsule') || d.contains('pill') || d.contains('bolus')) {
      return [
        "🍔 Hide in food: Place the pill inside a bread bun, a piece of cheese, or peanut butter.",
        "🔨 Powdering/Crushing: If approved by a vet, crush the tablet into powder and mix it with water or wet food.",
        "👅 Direct Placement: Place the pill deep on the back of the tongue, close the muzzle, and stroke the throat to trigger swallowing."
      ];
    } else if (d.contains('suspension') || d.contains('liquid') || d.contains('drops')) {
      return [
        "💉 Syringe Method: Use a needleless plastic syringe from the side of the mouth behind the canine teeth.",
        "💧 Slow Swallowing: Squirt in small intervals. Do NOT tilt the head straight up to prevent liquid entering the lungs."
      ];
    } else if (r.contains('topical') || d.contains('ointment') || d.contains('spot-on') || d.contains('cream')) {
      return [
        "🏷️ Base of Neck: Apply directly to the skin between the shoulder blades where the animal cannot lick it off.",
        "🚫 No Massage: Do not rub the spot in; let the liquid absorb naturally on the skin."
      ];
    }
    return [
      "🍲 Give with Meals: Most veterinary medicines are gentler on the stomach when served alongside food.",
      "📞 Consult Veterinarian: Check specific directions regarding food/water restrictions."
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FDA Animal Drug Registry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Search approved veterinary medicines to review active ingredients, administration routes, and reported adverse side effects.',
              style: TextStyle(fontSize: 12, color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search brand or ingredient (e.g. Meloxicam)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    minimumSize: const Size(60, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.critical, fontSize: 13))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _drugs.length,
                  itemBuilder: (ctx, i) {
                    final drug = _drugs[i];
                    final reactions = List<String>.from(drug['commonReactions'] ?? []);
                    final tips = _getAdministrationTips(drug['dosageForm'] ?? '', drug['route'] ?? '');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.teal.withOpacity(0.4)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(drug['brandName'] ?? 'Unknown Brand',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(12)),
                                child: Text(drug['route'] ?? 'Oral', style: const TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppColors.dark),
                              children: [
                                const TextSpan(text: 'Active Ingredient: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: drug['activeIngredient'] ?? 'N/A'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppColors.dark),
                              children: [
                                const TextSpan(text: 'Manufacturer: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: drug['manufacturer'] ?? 'N/A'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppColors.dark),
                              children: [
                                const TextSpan(text: 'Dosage Form: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: drug['dosageForm'] ?? 'N/A'),
                              ],
                            ),
                          ),
                          
                          // Practical Administration Tips
                          const SizedBox(height: 12),
                          const Text('💡 Administration Tips:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teal)),
                          const SizedBox(height: 6),
                          Column(
                            children: tips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal)),
                                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 11, color: AppColors.dark))),
                                ],
                              ),
                            )).toList(),
                          ),

                          if (reactions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('⚠️ Potential Adverse Reactions:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.critical)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: reactions.map((r) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.critical.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.critical.withOpacity(0.2)),
                                ),
                                child: Text(r, style: const TextStyle(fontSize: 10, color: AppColors.critical, fontWeight: FontWeight.w500)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
