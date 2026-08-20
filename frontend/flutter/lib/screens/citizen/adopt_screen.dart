import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../models/case_model.dart';
import '../../utils/app_colors.dart';
import '../../services/adoption_service.dart';
import '../../widgets/loading_button.dart';

class AdoptScreen extends StatefulWidget {
  const AdoptScreen({super.key});

  @override
  State<AdoptScreen> createState() => _AdoptScreenState();
}

class _AdoptScreenState extends State<AdoptScreen> {
  String _filter = 'All';

  final _filters = ['All', 'Dogs', 'Cats', 'Cows', 'Birds'];

  // Mock animals list representing the exact Stitch mockup layout
  final _mockPets = [
    {
      'name': 'Shera',
      'species': 'DOG',
      'location': 'Mumbai',
      'details': '2 Years • Male',
      'emoji': '🐕',
      'imageUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=400',
    },
    {
      'name': 'Mimi',
      'species': 'CAT',
      'location': 'Pune',
      'details': '6 Mos • Female',
      'emoji': '🐈',
      'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=400',
    },
    {
      'name': 'Nandi',
      'species': 'COW',
      'location': 'Nashik',
      'details': '4 Years • Male',
      'emoji': '🐄',
      'imageUrl': 'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?auto=format&fit=crop&q=80&w=400',
    },
    {
      'name': 'Mithu',
      'species': 'BIRD',
      'location': 'Delhi',
      'details': '1 Year • Unsexed',
      'emoji': '🐦',
      'imageUrl': 'https://images.unsplash.com/photo-1552728089-57bdde30ebd3?auto=format&fit=crop&q=80&w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchOpenCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPets = _mockPets.where((pet) {
      if (_filter == 'All') return true;
      if (_filter == 'Dogs' && pet['species'] == 'DOG') return true;
      if (_filter == 'Cats' && pet['species'] == 'CAT') return true;
      if (_filter == 'Cows' && pet['species'] == 'COW') return true;
      if (_filter == 'Birds' && pet['species'] == 'BIRD') return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.dark),
            const SizedBox(width: 14),
            Text(
              'Karuṇā',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.teal,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tealLight,
              child: const Text('👨', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Adopt a Rescued Animal',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🐾', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Find your forever companion among our brave survivors.',
                  style: GoogleFonts.inter(
                    color: AppColors.gray,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final item = _filters[idx];
                  final active = _filter == item;
                  return ChoiceChip(
                    label: Text(item),
                    selected: active,
                    selectedColor: AppColors.teal,
                    backgroundColor: const Color(0xFFEFF6FF), // soft blue/gray
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: active ? AppColors.teal : Colors.transparent,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filter = item);
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // Animals Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.64,
              ),
              itemCount: filteredPets.length,
              itemBuilder: (ctx, i) {
                final pet = filteredPets[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo container with "AVAILABLE" badge overlay
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: Image.network(
                                  pet['imageUrl']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AVAILABLE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Text Info details
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pet['name']!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.dark,
                                  ),
                                ),
                                Text(
                                  pet['species']!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.gray),
                                const SizedBox(width: 4),
                                Text(
                                  pet['location']!,
                                  style: GoogleFonts.inter(color: AppColors.gray, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pet['details']!,
                              style: GoogleFonts.inter(
                                color: AppColors.dark.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _showAdoptDialog(context, pet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Meet Me',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAdoptDialog(BuildContext context, Map<String, String> pet) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool loading = false;
    String? adopterIdUrl;
    String? kycDocName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(pet['emoji']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adopt ${pet['name']}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        pet['location']!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contactCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Why do you want to adopt?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KYC Identity Scan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kycDocName ?? 'No verification document attached',
                          style: TextStyle(
                            fontSize: 11,
                            color: kycDocName != null ? Colors.green[700] : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final mockDocs = [
                        'Aadhaar_ID_Verified.jpg',
                        'PAN_Card_Verified.jpg',
                        'Voter_Card_Verified.jpg'
                      ];
                      setState(() {
                        kycDocName = mockDocs[DateTime.now().millisecond % mockDocs.length];
                        adopterIdUrl = 'https://res.cloudinary.com/karuna/image/upload/$kycDocName';
                      });
                    },
                    icon: const Icon(Icons.attach_file, size: 14),
                    label: const Text('Attach KYC', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Submit Adoption Request',
                loading: loading,
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    await AdoptionService.applyForAdoption(
                      caseId: 1,
                      applicantName: nameCtrl.text.trim(),
                      contact: contactCtrl.text.trim(),
                      reason: reasonCtrl.text.trim(),
                      adopterIdUrl: adopterIdUrl,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🐾 Adoption request submitted! We\'ll contact you soon.'),
                        backgroundColor: AppColors.teal,
                      ),
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
