import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../models/case_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../services/adoption_service.dart';
import '../../widgets/loading_button.dart';

class AdoptScreen extends StatefulWidget {
  const AdoptScreen({super.key});

  @override
  State<AdoptScreen> createState() => _AdoptScreenState();
}

class _AdoptScreenState extends State<AdoptScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchOpenCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>();
    final pets = cases.openCases.where((c) {
      if (_filter != 'All' && c.species?.toLowerCase() != _filter.toLowerCase()) return false;
      if (_searchCtrl.text.isNotEmpty &&
          !(c.species?.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ?? false)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Adopt a Pet'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by species...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Dog', 'Cat', 'Cow', 'Bird'].map((f) {
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.teal : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: active ? Colors.white : AppColors.dark,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),

          Expanded(
            child: cases.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : pets.isEmpty
                    ? const Center(child: Text('No pets available for adoption right now.', style: TextStyle(color: AppColors.gray)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: pets.length,
                        itemBuilder: (ctx, i) => _PetCard(pet: pets[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final CaseModel pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAdoptDialog(context, pet),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(child: Text(pet.speciesEmoji, style: const TextStyle(fontSize: 58))),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.species ?? 'Animal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(pet.locationLabel ?? '', style: const TextStyle(fontSize: 10, color: AppColors.gray), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () => _showAdoptDialog(context, pet),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Adopt 🐾', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdoptDialog(BuildContext context, CaseModel pet) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(pet.speciesEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Adopt this ${pet.species ?? 'Animal'}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    Text(pet.locationLabel ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ]),
                ],
              ),
              const Divider(height: 24),
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.gray))),
              const SizedBox(height: 12),
              TextFormField(controller: contactCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.gray))),
              const SizedBox(height: 12),
              TextFormField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Why do you want to adopt?', alignLabelWithHint: true)),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Submit Adoption Request',
                loading: loading,
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    await AdoptionService.applyForAdoption(
                      caseId: pet.id,
                      applicantName: nameCtrl.text.trim(),
                      contact: contactCtrl.text.trim(),
                      reason: reasonCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🐾 Adoption request submitted! We\'ll contact you soon.'), backgroundColor: AppColors.teal),
                    );
                  } catch (e) {
                    setState(() => loading = false);
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
}
