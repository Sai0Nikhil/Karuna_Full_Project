import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';
import 'sita_chat_screen.dart';

class ReportFlow extends StatefulWidget {
  const ReportFlow({super.key});

  @override
  State<ReportFlow> createState() => _ReportFlowState();
}

class _ReportFlowState extends State<ReportFlow> {
  int _step = 0;

  // Photo + location
  XFile? _photo;
  String? _photoBase64;
  double? _lat, _lon;
  bool _gettingLocation = false;
  String? _locationLabel;
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // AI analysis
  AiAnalysisResult? _analysis;
  bool _analyzing = false;
  String? _analyzeError;
  int? _submittedCaseId;

  // Per-step detailed instructions state
  final Map<int, String?> _stepDetails = {};
  final Map<int, bool> _stepLoading = {};

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ─── GPS ──────────────────────────────────────────────────────────────────
  Future<void> _getGps() async {
    setState(() { _gettingLocation = true; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _showSnack('Location permission denied. Enter manually.');
        setState(() { _gettingLocation = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _locationLabel = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _gettingLocation = false;
      });
    } catch (e) {
      _showSnack('Could not get location. Enter manually below.');
      setState(() { _gettingLocation = false; });
    }
  }

  // ─── Photo ────────────────────────────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() {
      _photo = file;
      _photoBase64 = 'data:$mime;base64,$b64';
      _analysis = null;
      _analyzeError = null;
    });
  }

  // ─── AI Analyze ───────────────────────────────────────────────────────────
  Future<void> _analyzePhoto() async {
    if (_photoBase64 == null) return;
    setState(() { _analyzing = true; _analyzeError = null; });

    final result = await AiService.analyzePhoto(
      _photoBase64!,
      lat: _lat,
      lon: _lon,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    setState(() {
      _analyzing = false;
      if (result != null) {
        _analysis = result;
        _step = 1;
      } else {
        _analyzeError = 'AI analysis failed. Check your connection and try again.';
      }
    });
  }

  // ─── Get Detailed Instruction per step ───────────────────────────────────
  Future<void> _loadStepDetail(int index, String step) async {
    if (_stepDetails.containsKey(index)) return;
    setState(() { _stepLoading[index] = true; });
    final detail = await AiService.getDetailedInstruction(
      step: step,
      animal: _analysis?.species ?? 'animal',
    );
    setState(() {
      _stepDetails[index] = detail ?? 'Keep the animal calm and follow the step carefully.';
      _stepLoading[index] = false;
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cases = context.read<CaseProvider>();
    final locLabel = _locationLabel ??
        (_locationCtrl.text.isNotEmpty
            ? '${_locationCtrl.text.trim()}, ${_cityCtrl.text.trim()}'
            : 'Unknown location');

    final result = await cases.createCase(
      reporterName: auth.user?.name ?? 'Anonymous',
      reporterContact: auth.user?.email,
      species: _analysis?.species,
      injuryType: _analysis?.injuryType,
      severity: _analysis?.severity,
      locationLabel: locLabel,
      probableCondition: _analysis?.probableCondition,
      latitude: _lat,
      longitude: _lon,
      imageDataUrl: _photoBase64,
      photoPath: _photo?.path,
      firstAidSteps: _analysis?.firstAidSteps,
      estimatedCostInr: _analysis?.estimatedCostInr,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _submittedCaseId = result.id;
        _step = 3;
      });
    } else {
      _showSnack(cases.error ?? 'Failed to submit');
    }
  }

  Future<void> _downloadCertificate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final name = auth.user?.name ?? 'Anonymous Compassionate Citizen';
    final dateStr = DateTime.now().day.toString() + ' ' + 
        _getMonthName(DateTime.now().month) + ' ' + 
        DateTime.now().year.toString();
        
    final caseId = _submittedCaseId != null ? _submittedCaseId.toString() : 'N/A';

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(
                color: PdfColor.fromHex('#D97706'), // Gold / Amber-600
                width: 6,
              ),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#0F766E'), // Teal-700
                  width: 1.5,
                ),
              ),
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'CERTIFICATE OF APPRECIATION',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#0F766E'),
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#64748B'),
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 18),
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#1E293B'),
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Container(
                        width: 250,
                        height: 1.5,
                        color: PdfColor.fromHex('#0F766E'),
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                      ),
                      pw.SizedBox(height: 18),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                        child: pw.Text(
                          'For showing outstanding compassion, care, and prompt action in reporting an animal in distress to the Karuṇā Rescue Network. Your immediate support has directly contributed to saving a life and making the world a kinder place.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#475569'),
                            fontSize: 11,
                            lineSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CASE ID: $caseId',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#0F766E'),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.Text(
                            'DATE: $dateStr',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#475569'),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 100,
                            height: 1,
                            color: PdfColor.fromHex('#0F766E'),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Karuṇā Team Signatory',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#475569'),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Karuna_Certificate_$caseId.pdf',
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.critical),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitle()),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
      ),
      body: Column(
        children: [
          if (_step < 3) _buildProgress(),
          Expanded(
            child: switch (_step) {
              0 => _buildPhotoStep(),
              1 => _buildAnalysisResult(),
              2 => _buildLocationStep(),
              _ => _buildSuccess(),
            },
          ),
        ],
      ),
    );
  }

  String _stepTitle() => switch (_step) {
    0 => '📸 Photo + Location',
    1 => '🤖 AI Analysis',
    2 => '📍 Confirm Location',
    _ => '✅ Submitted',
  };

  Widget _buildProgress() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Row(children: [
                _stepDot(i, i < _step ? 'done' : i == _step ? 'active' : 'pending'),
                if (i < 2) Expanded(child: Container(
                  height: 2,
                  color: i < _step ? AppColors.teal : AppColors.lightGray,
                )),
              ]),
            )),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Photo', style: TextStyle(fontSize: 10, color: AppColors.gray)),
              Text('AI Report', style: TextStyle(fontSize: 10, color: AppColors.gray)),
              Text('Location', style: TextStyle(fontSize: 10, color: AppColors.gray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String state) {
    final bg = state == 'pending' ? AppColors.lightGray : AppColors.teal;
    final child = state == 'done'
        ? const Icon(Icons.check, color: Colors.white, size: 12)
        : Text('${index + 1}', style: TextStyle(
            color: state == 'pending' ? AppColors.gray : Colors.white,
            fontSize: 11, fontWeight: FontWeight.bold));
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  // ─── Step 0: Photo + GPS ──────────────────────────────────────────────────
  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Found an animal in distress? Upload a photo + share your location.',
              style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 20),

          // Photo preview
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _photo != null ? AppColors.teal : AppColors.lightGray,
                  width: _photo != null ? 2 : 1,
                ),
              ),
              child: _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_photo!.path), fit: BoxFit.cover),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _photoBarBtn(Icons.camera_alt, 'Retake', () => _pickPhoto(ImageSource.camera)),
                                  _photoBarBtn(Icons.photo_library, 'Change Photo', () => _pickPhoto(ImageSource.gallery)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.teal, size: 36),
                        ),
                        const SizedBox(height: 14),
                        const Text('Upload a photo of the animal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark)),
                        const SizedBox(height: 4),
                        const Text('Tap to use Camera or Gallery', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Camera / Gallery buttons when no photo yet
          if (_photo == null)
            Row(children: [
              Expanded(child: _photoBtn(Icons.camera_alt_outlined, 'Camera', () => _pickPhoto(ImageSource.camera))),
              const SizedBox(width: 12),
              Expanded(child: _photoBtn(Icons.photo_library_outlined, 'Gallery', () => _pickPhoto(ImageSource.gallery))),
            ]),

          const SizedBox(height: 20),

          // Location section
          const Text('📍 Share Your Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 10),

          // GPS button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _gettingLocation ? null : _getGps,
              icon: _gettingLocation
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location, size: 18),
              label: Text(_gettingLocation ? 'Getting location...' : '📍 Use Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_locationLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.teal, size: 16),
                const SizedBox(width: 6),
                Text('Location captured: $_locationLabel',
                    style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],

          const SizedBox(height: 10),
          const Center(child: Text('OR', style: TextStyle(color: AppColors.gray, fontSize: 12))),
          const SizedBox(height: 10),

          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Connaught Place, Delhi',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.gray),
            ),
            onChanged: (v) {
              if (v.isNotEmpty) setState(() { _locationLabel = v; _lat = null; _lon = null; });
            },
          ),
          const SizedBox(height: 16),

          // Optional description
          const Text('Describe the situation (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "e.g. 'The dog can't walk on its back leg.'",
            ),
          ),
          const SizedBox(height: 24),

          if (_analyzeError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.criticalBg, borderRadius: BorderRadius.circular(12)),
              child: Text(_analyzeError!, style: const TextStyle(color: AppColors.critical, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],

          LoadingButton(
            label: _photo == null ? 'Add Photo to Continue' : '🤖 Analyze with AI',
            loading: _analyzing,
            onPressed: _photo == null ? null : _analyzePhoto,
          ),
          const SizedBox(height: 12),
          if (_photo == null)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('Skip AI → Manual report', style: TextStyle(color: AppColors.gray, fontSize: 12)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.teal),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _photoBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.teal, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _photoBarBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── Step 1: AI Analysis Result ───────────────────────────────────────────
  Widget _buildAnalysisResult() {
    final a = _analysis!;
    final severityColor = a.severityColor;
    final medicines = a.medicineList;
    final firstAid = a.firstAidList;
    final vets = a.localSupportList;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Analysis Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const Spacer(),
                if (a.confidence != null)
                  _badge(a.confidence!.toUpperCase(), AppColors.teal, AppColors.tealLight),
              ]),
              const SizedBox(height: 14),

              _labelValue('Animal', _formatSpecies(a.species ?? a.injuryType ?? 'Unknown')),
              const SizedBox(height: 6),
              Row(children: [
                const Text('Status: ', style: TextStyle(fontSize: 13, color: AppColors.gray)),
                _badge('Injured', AppColors.critical, AppColors.criticalBg),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Text('Severity: ', style: TextStyle(fontSize: 13, color: AppColors.gray)),
                _badge((a.severity ?? 'urgent').toUpperCase(), severityColor, severityColor.withOpacity(0.1)),
              ]),

              if (a.probableCondition != null) ...[
                const SizedBox(height: 12),
                const Text('Probable Condition:', style: TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(a.probableCondition!, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // ── Prescription & Administration Guide ────────────────────────
          if (medicines.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Text('🧪 ', style: TextStyle(fontSize: 18)),
                  Text('Prescription & Administration Guide',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                ]),
                const SizedBox(height: 4),
                const Text('* AI Suggestions Only. Consult a vet before administering.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                ...medicines.map((m) => _expandableMedicineCard(m)),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Immediate First Aid ────────────────────────────────────────
          if (firstAid.isNotEmpty) ...[
            const Text('Immediate First Aid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 8),
            ...firstAid.asMap().entries.map((e) => _firstAidStep(e.key, e.value, a.species ?? 'animal')),
            const SizedBox(height: 12),
          ],

          // ── Warning banner ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              border: const Border(left: BorderSide(color: Color(0xFFF9A825), width: 4)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚠️ ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  a.disclaimer ?? 'This is emergency first aid only. Severe wounds require immediate professional veterinary care. Do not attempt treatment if animal is aggressive.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF795548), height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Nearby Support ─────────────────────────────────────────────
          const Text('Nearby Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.teal)),
          const SizedBox(height: 10),
          if (vets.isNotEmpty)
            ...vets.map((v) => _vetCard(v))
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecor(),
              child: const Text('No specific contacts found for your location. Search "vet near me" on Google Maps.',
                  style: TextStyle(fontSize: 13, color: AppColors.gray)),
            ),
          const SizedBox(height: 16),

          // ── Talk to Sita ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SitaChatScreen(
                species: _analysis?.species,
                initialContext: _analysis?.probableCondition,
              ),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Talk to Sita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Need guidance? Sita is here to help step-by-step.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Start Chat', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              border: Border.all(color: const Color(0xFFFFCC02)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Send this to KARUNA responders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF795548))),
              const SizedBox(height: 4),
              const Text('Saves this report as a tracked case — NGO dispatchers will be notified.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E7B0E))),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit case →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('← Retake Photo', style: TextStyle(color: AppColors.gray)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _firstAidStep(int index, String step, String animal) {
    final detail = _stepDetails[index];
    final loading = _stepLoading[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(step, style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A5F), height: 1.5))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: detail != null
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.dark, height: 1.5)),
                      const SizedBox(height: 4),
                      const Text('AI-generated instructions', style: TextStyle(fontSize: 10, color: AppColors.gray)),
                    ]),
                  )
                : GestureDetector(
                    onTap: loading ? null : () => _loadStepDetail(index, step),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                            )
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('📋 ', style: TextStyle(fontSize: 12)),
                              Text('Get Detailed Instructions',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                            ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _expandableMedicineCard(Map<String, dynamic> m) {
    return _ExpandableCard(
      emoji: m['route']?.toString().toLowerCase().contains('topical') == true ? '🧴' : '💊',
      name: m['name'] ?? '',
      route: m['route'] ?? '',
      detail: '${m['dosage'] ?? ''} — ${m['frequency'] ?? ''}\n${m['notes'] ?? ''}',
    );
  }

  Widget _vetCard(Map<String, dynamic> v) {
    final name = v['name'] ?? 'Veterinary Clinic';
    final address = v['address'] ?? '';
    final phone = v['phone'] ?? 'N/A';
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name $address')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
        if (address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (phone != 'N/A' && !phone.contains('N/A')) ...[
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('📞 ', style: TextStyle(fontSize: 14)),
                Text('Call Now', style: TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 20),
          ],
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🗺️ ', style: TextStyle(fontSize: 14)),
              Text('View on Map', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ]),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
  );

  Widget _badge(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.bold)),
  );

  Widget _labelValue(String label, String value) => Row(children: [
    Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
    Text(value, style: const TextStyle(fontSize: 13, color: AppColors.dark, fontWeight: FontWeight.w600)),
  ]);

  String _formatSpecies(String? s) {
    if (s == null) return 'Unknown';
    final m = {'dog': '🐕 Dog', 'cat': '🐈 Cat', 'cow': '🐄 Cattle/Cow', 'bird': '🦜 Bird', 'other': '❓ Other'};
    return m[s.toLowerCase()] ?? s;
  }

  // ─── Step 2: Location ─────────────────────────────────────────────────────
  Widget _buildLocationStep() {
    final cases = context.watch<CaseProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Confirm Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
        const SizedBox(height: 4),
        const Text('Help rescuers find the animal quickly', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 20),

        if (_locationLabel != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.location_on, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Location: $_locationLabel',
                  style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 14),
        ],

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
        const SizedBox(height: 28),

        LoadingButton(label: 'Submit Report 🐾', loading: cases.loading, onPressed: _submit),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = _analysis != null ? 1 : 0),
          child: const Text('← Back', style: TextStyle(color: AppColors.gray)),
        ),
      ]),
    );
  }

  // ─── Step 3: Success ──────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            onPressed: () => setState(() {
              _step = 0; _photo = null; _photoBase64 = null;
              _analysis = null; _lat = null; _lon = null; _locationLabel = null;
              _stepDetails.clear(); _stepLoading.clear();
            }),
            child: const Text('Report Another'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _downloadCertificate,
            icon: const Icon(Icons.workspace_premium_outlined, size: 20),
            label: const Text('Download Certificate 📜'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
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
        ]),
      ),
    );
  }
}

// ─── Expandable Medicine Card ─────────────────────────────────────────────────
class _ExpandableCard extends StatefulWidget {
  final String emoji, name, route, detail;
  const _ExpandableCard({required this.emoji, required this.name, required this.route, required this.detail});

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Text('${widget.emoji} ', style: const TextStyle(fontSize: 16)),
                Expanded(child: Text(widget.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark))),
                if (widget.route.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(6)),
                    child: Text(widget.route, style: const TextStyle(fontSize: 10, color: AppColors.teal)),
                  ),
                const SizedBox(width: 8),
                Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray, size: 20),
              ]),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5F5),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
              ),
              child: Text(widget.detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.dark, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
