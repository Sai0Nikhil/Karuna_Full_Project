import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/diamond_background.dart';
import '../../widgets/loading_button.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  String _language = 'English';
  String _species = 'dog';
  String _injury = 'Fracture';
  FirstAidResult? _result;
  bool _loading = false;

  final _languages = [
    {'code': 'English', 'label': 'English'},
    {'code': 'Telugu', 'label': 'తెలుగు'},
    {'code': 'Hindi', 'label': 'हिन्दी'},
    {'code': 'Tamil', 'label': 'தமிழ்'},
    {'code': 'Kannada', 'label': 'ಕನ್ನಡ'}
  ];

  final _speciesList = [
    {'code': 'dog', 'label': 'DOG', 'emoji': '🐕'},
    {'code': 'cat', 'label': 'CAT', 'emoji': '🐈'},
    {'code': 'cow', 'label': 'COW', 'emoji': '🐄'},
    {'code': 'bird', 'label': 'BIRD', 'emoji': '🐦'}
  ];

  final _injuries = [
    'Wound',
    'Fracture',
    'Bleeding',
    'Poisoning',
    'Burn',
    'Heat Stroke'
  ];

  @override
  void initState() {
    super.initState();
    _fetchFirstAid();
  }

  Future<void> _fetchFirstAid() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final res = await AiService.getFirstAid(
        species: _species,
        injuryDescription: _injury,
        language: _language,
      );
      setState(() {
        _result = res;
      });
    } catch (_) {}
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency First Aid',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.teal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
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
      body: LightDiamondBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Select Language Section
                  _sectionHeader('SELECT LANGUAGE'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _languages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final item = _languages[idx];
                        final active = _language == item['code'];
                        return ChoiceChip(
                          label: Text(item['label']!),
                          selected: active,
                          selectedColor: AppColors.teal,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: active ? Colors.white : AppColors.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: active ? AppColors.teal : AppColors.divider,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _language = item['code']!);
                              _fetchFirstAid();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Affected Species Section
                  _sectionHeader('AFFECTED SPECIES'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _speciesList.map((item) {
                      final active = _species == item['code'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _species = item['code']!);
                          _fetchFirstAid();
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: active ? AppColors.teal : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: active ? AppColors.teal : AppColors.divider,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  item['emoji']!,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: active ? AppColors.teal : AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Type of Injury Section
                  _sectionHeader('TYPE OF INJURY'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _injuries.map((injuryItem) {
                      final active = _injury == injuryItem;
                      return ChoiceChip(
                        label: Text(injuryItem),
                        selected: active,
                        selectedColor: AppColors.teal,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : AppColors.dark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: active ? AppColors.teal : AppColors.divider,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _injury = injuryItem);
                            _fetchFirstAid();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Results Container
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.teal),
                      ),
                    )
                  else if (_result != null) ...[
                    // Emergency steps card
                    _buildEmergencyStepsCard(),
                    const SizedBox(height: 16),

                    // DO NOT DO card
                    _buildDoNotDoCard(),
                    const SizedBox(height: 16),

                    // Call a vet warning card
                    _buildCallVetWarning(),
                    const SizedBox(height: 24),
                  ]
                ],
              ),
            ),

            // Chat with Sita live banner
            _buildSitaLiveBanner(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.gray,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmergencyStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medical_services_outlined,
                    color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency Steps: $_injury',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._result!.immediateSteps.asMap().entries.map((e) {
            final idx = e.key + 1;
            final stepText = e.value;
            // Split title and description if it has a colon
            final parts = stepText.split(': ');
            final title = parts.isNotEmpty ? parts[0] : 'Step $idx';
            final desc = parts.length > 1 ? parts[1] : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.teal,
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.dark,
                          ),
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.gray,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDoNotDoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.criticalBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.critical.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: AppColors.critical, size: 20),
              const SizedBox(width: 10),
              Text(
                'DO NOT DO',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.doNotDo.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            color: AppColors.critical,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.critical.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCallVetWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.urgentBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.urgent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.urgent, size: 20),
              const SizedBox(width: 10),
              Text(
                'When to call a vet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.urgent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _result!.whenToCallVet ?? 'Call vet immediately if unconscious or bleeding heavily.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.urgent.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSitaLiveBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/citizen/sita'),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with Sita',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'LIVE EMERGENCY HELP',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
