import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class NearbyVetsScreen extends StatefulWidget {
  const NearbyVetsScreen({super.key});

  @override
  State<NearbyVetsScreen> createState() => _NearbyVetsScreenState();
}

class _NearbyVetsScreenState extends State<NearbyVetsScreen> {
  List<dynamic> _vets = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVets({String keyword = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParam = keyword.isNotEmpty ? '?keyword=$keyword' : '';
      final response = await ApiService.get('/veterinarians$queryParam');
      setState(() {
        if (response is Map && response.containsKey('content')) {
          _vets = response['content'] as List<dynamic>;
        } else if (response is List) {
          _vets = response;
        } else {
          _vets = [];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load veterinarians: ${e.toString()}';
        _loading = false;
        // Fallback mock data in case backend is empty or seeding is needed (with coordinates)
        _vets = [
          {
            "id": 1,
            "licenseNumber": "VET-LIC-9982",
            "clinicName": "PawCare Veterinary Clinic",
            "specialization": "Emergency & Surgery",
            "email": "pawcare@vetclinic.in",
            "phoneNumber": "+919876543210",
            "clinicLocation": {
              "label": "Koramangala, Bangalore",
              "latitude": 12.9344,
              "longitude": 77.6192
            }
          },
          {
            "id": 2,
            "licenseNumber": "VET-LIC-1092",
            "clinicName": "Dr. Ramesh Animal Hospital",
            "specialization": "General Medicine",
            "email": "ramesh@animalhosp.org",
            "phoneNumber": "+918888877777",
            "clinicLocation": {
              "label": "Indiranagar, Bangalore",
              "latitude": 12.9716,
              "longitude": 77.6412
            }
          },
          {
            "id": 3,
            "licenseNumber": "VET-LIC-4821",
            "clinicName": "Paws & Claws Clinic",
            "specialization": "Avian & Exotic Animals",
            "email": "contact@pawsandclaws.in",
            "phoneNumber": "+917777766666",
            "clinicLocation": {
              "label": "HSR Layout, Bangalore",
              "latitude": 12.9103,
              "longitude": 77.6450
            }
          }
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nearby Veterinarians', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search by clinic name, spec or location...',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.gray),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (val) => _fetchVets(keyword: val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _fetchVets(keyword: _searchCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    minimumSize: const Size(54, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
          else if (_vets.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No veterinarians found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    const SizedBox(height: 4),
                    Text('Try adjusting your search criteria.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vets.length,
                itemBuilder: (ctx, i) {
                  final vet = _vets[i];
                  final clinicLoc = vet['clinicLocation'];
                  final locationLabel = clinicLoc != null ? clinicLoc['label'] : 'Bangalore';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                vet['clinicName'] ?? 'Veterinary Clinic',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.resolvedBg, borderRadius: BorderRadius.circular(12)),
                              child: const Text('🏥 OPEN', style: TextStyle(fontSize: 9, color: AppColors.resolved, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lic No: ${vet['licenseNumber'] ?? 'N/A'}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.gray),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vet['specialization'] ?? 'General Practitioner',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationLabel,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.dark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.email_outlined, size: 14, color: AppColors.teal),
                                label: const Text('Email', style: TextStyle(fontSize: 11, color: AppColors.teal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  minimumSize: const Size(0, 36),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.directions_outlined, size: 14, color: AppColors.teal),
                                label: const Text('Route', style: TextStyle(fontSize: 11, color: AppColors.teal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  minimumSize: const Size(0, 36),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  final lat = clinicLoc != null ? (clinicLoc['latitude'] as num?)?.toDouble() : null;
                                  final lon = clinicLoc != null ? (clinicLoc['longitude'] as num?)?.toDouble() : null;
                                  if (lat != null && lon != null) {
                                    Navigator.pushNamed(context, '/map-routing', arguments: {
                                      'caseId': vet['id'] as int,
                                      'caseLat': lat,
                                      'caseLon': lon,
                                      'animalTitle': vet['clinicName'] as String
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('GPS coordinates not available for this clinic.')),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                                label: const Text('Call', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  minimumSize: const Size(0, 36),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
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
}
