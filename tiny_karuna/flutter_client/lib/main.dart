import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const TinyKarunaApp());
}

class TinyKarunaApp extends StatelessWidget {
  const TinyKarunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiny Karuṇā',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const MainShowcaseScreen(),
    );
  }
}

class MainShowcaseScreen extends StatefulWidget {
  const MainShowcaseScreen({super.key});

  @override
  State<MainShowcaseScreen> createState() => _MainShowcaseScreenState();
}

class _MainShowcaseScreenState extends State<MainShowcaseScreen> {
  // Global API Endpoint config
  final _apiController = TextEditingController(text: 'http://192.168.31.211:8002');
  
  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F766E), // Brand Teal
          foregroundColor: Colors.white,
          title: const Text(
            '🐾 Tiny Karuṇā ML Showcase',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.emergency_outlined), text: 'Triage'),
              Tab(icon: Icon(Icons.favorite_outline), text: 'Pain Index'),
              Tab(icon: Icon(Icons.image_search_outlined), text: 'Skin CV'),
            ],
          ),
        ),
        body: Column(
          children: [
            // API Config panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _apiController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'FastAPI Endpoint Base URL',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TriageTab(baseUrlController: _apiController),
                  PainIndexTab(baseUrlController: _apiController),
                  SkinTab(baseUrlController: _apiController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚨 Tab 1: Emergency Triage
class TriageTab extends StatefulWidget {
  final TextEditingController baseUrlController;
  const TriageTab({super.key, required this.baseUrlController});

  @override
  State<TriageTab> createState() => _TriageTabState();
}

class _TriageTabState extends State<TriageTab> {
  String _species = 'dog';
  String _injuryType = 'wound';
  final _descController = TextEditingController(
      text: 'A stray animal is lying near market with cut wound bleeding.');

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _runPrediction() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final url = Uri.parse('${widget.baseUrlController.text}/predict-triage');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'species': _species,
          'injury_type': _injuryType,
          'description': _descController.text,
        }),
      );

      if (resp.statusCode == 200) {
        setState(() {
          _result = jsonDecode(resp.body);
          _loading = false;
        });
      } else {
        throw Exception('Server returned status code ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚨 Emergency Case Triage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _species,
                  decoration: const InputDecoration(labelText: 'Species'),
                  items: const [
                    DropdownMenuItem(value: 'dog', child: Text('Dog')),
                    DropdownMenuItem(value: 'cat', child: Text('Cat')),
                    DropdownMenuItem(value: 'cow', child: Text('Cow')),
                    DropdownMenuItem(value: 'bird', child: Text('Bird')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _species = v ?? 'dog'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _injuryType,
                  decoration: const InputDecoration(labelText: 'Injury Type'),
                  items: const [
                    DropdownMenuItem(value: 'bleeding', child: Text('Bleeding')),
                    DropdownMenuItem(value: 'fracture', child: Text('Fracture / Broken')),
                    DropdownMenuItem(value: 'wound', child: Text('Wound')),
                    DropdownMenuItem(value: 'emaciation', child: Text('Emaciation / Starvation')),
                    DropdownMenuItem(value: 'weakness', child: Text('Weakness')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _injuryType = v ?? 'wound'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Symptom Description'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) _errorAlert(_error!),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.flash_on),
              label: const Text('Evaluate Urgent Severity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _runPrediction,
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) ...[
            const Text('🔮 Prediction Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Severity Level: ${_result!['severity']?.toString().toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F766E))),
                  const SizedBox(height: 6),
                  Text('Confidence Score: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                  Text('Estimated Cost: ₹${_result!['estimatedCostInr']}'),
                  const SizedBox(height: 6),
                  Text('Diagnosis: ${_result!['probableCondition']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 🩺 Tab 2: Clinical Pain Index
class PainIndexTab extends StatefulWidget {
  final TextEditingController baseUrlController;
  const PainIndexTab({super.key, required this.baseUrlController});

  @override
  State<PainIndexTab> createState() => _PainIndexTabState();
}

class _PainIndexTabState extends State<PainIndexTab> {
  int _gcps1 = 0;
  int _gcps2 = 0;
  int _gcps3 = 0;
  int _gcps4 = 0;
  final _weightController = TextEditingController(text: '15.0');
  final _tempController = TextEditingController(text: '38.5');
  final _hrController = TextEditingController(text: '100');

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _runPainPrediction() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final url = Uri.parse('${widget.baseUrlController.text}/predict-pain');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'breed': 'unknown_breed',
          'sex': 'unknown_sex',
          'neuterStatus': 'unknown_status',
          'weight': double.tryParse(_weightController.text) ?? 15.0,
          'gcps1': _gcps1,
          'gcps2': _gcps2,
          'gcps3': _gcps3,
          'gcps4': _gcps4,
          'temperature': double.tryParse(_tempController.text) ?? 38.5,
          'heartRate': double.tryParse(_hrController.text) ?? 100.0,
        }),
      );

      if (resp.statusCode == 200) {
        setState(() {
          _result = jsonDecode(resp.body);
          _loading = false;
        });
      } else {
        throw Exception('Server returned status code ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _tempController.dispose();
    _hrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🩺 Glasgow Pain Scale (GCPS)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _gcps1,
                  decoration: const InputDecoration(labelText: '1. Kennel Behaviour / Posture'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Quiet (0)')),
                    DropdownMenuItem(value: 1, child: Text('Crying / Whimpering (1)')),
                  ],
                  onChanged: (v) => setState(() => _gcps1 = v ?? 0),
                ),
                DropdownButtonFormField<int>(
                  value: _gcps2,
                  decoration: const InputDecoration(labelText: '2. Response to Pain Site'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Ignoring pain (0)')),
                    DropdownMenuItem(value: 1, child: Text('Looking at site (1)')),
                    DropdownMenuItem(value: 2, child: Text('Licking site (2)')),
                    DropdownMenuItem(value: 3, child: Text('Rubbing or scratching (3)')),
                  ],
                  onChanged: (v) => setState(() => _gcps2 = v ?? 0),
                ),
                DropdownButtonFormField<int>(
                  value: _gcps3,
                  decoration: const InputDecoration(labelText: '3. Mobility / Walking'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Normal walk (0)')),
                    DropdownMenuItem(value: 1, child: Text('Lame (1)')),
                    DropdownMenuItem(value: 2, child: Text('Slow and reluctant (2)')),
                    DropdownMenuItem(value: 3, child: Text('Stiff (3)')),
                    DropdownMenuItem(value: 4, child: Text('Refuses to move (4)')),
                  ],
                  onChanged: (v) => setState(() => _gcps3 = v ?? 0),
                ),
                DropdownButtonFormField<int>(
                  value: _gcps4,
                  decoration: const InputDecoration(labelText: '4. Touch Response (around site)'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Do nothing (0)')),
                    DropdownMenuItem(value: 1, child: Text('Look round (1)')),
                    DropdownMenuItem(value: 2, child: Text('Flinch (2)')),
                    DropdownMenuItem(value: 3, child: Text('Growl or guard area (3)')),
                    DropdownMenuItem(value: 4, child: Text('Snap (4)')),
                    DropdownMenuItem(value: 5, child: Text('Cry (5)')),
                  ],
                  onChanged: (v) => setState(() => _gcps4 = v ?? 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🩺 Physiological Vitals (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _card(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Temp (°C)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'HR (bpm)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) _errorAlert(_error!),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.health_and_safety),
              label: const Text('Calculate Pain Index'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _runPainPrediction,
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) ...[
            const Text('🔮 Prediction Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pain Severity: ${_result!['painLevel']?.toString().toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber-900)),
                  const SizedBox(height: 6),
                  Text('Confidence Score: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 6),
                  Text('Clinical Advice: ${_result!['advice']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 👁️ Tab 3: Skin Disease Classifier
class SkinTab extends StatefulWidget {
  final TextEditingController baseUrlController;
  const SkinTab({super.key, required this.baseUrlController});

  @override
  State<SkinTab> createState() => _SkinTabState();
}

class _SkinTabState extends State<SkinTab> {
  File? _imageFile;
  final _picker = ImagePicker();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error selecting image: $e');
    }
  }

  Future<void> _uploadAndClassify() async {
    if (_imageFile == null) return;
    
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final url = Uri.parse('${widget.baseUrlController.text}/predict-skin');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final responseStream = await request.send();
      final resp = await http.Response.fromStream(responseStream);

      if (resp.statusCode == 200) {
        setState(() {
          _result = jsonDecode(resp.body);
          _loading = false;
        });
      } else {
        throw Exception('Server returned status code ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👁️ Skin Disease Classifier (YOLOv8)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                if (_imageFile == null)
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) _errorAlert(_error!),
          if (_imageFile != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload & Classify Skin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading ? null : _uploadAndClassify,
              ),
            ),
          const SizedBox(height: 20),
          if (_result != null) ...[
            const Text('🔮 Prediction Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condition: ${_result!['skinClass']?.toString().toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF16A34A))),
                  const SizedBox(height: 6),
                  Text('Confidence Score: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 6),
                  Text(_result!['message'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Global UI helper widgets
Widget _card({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

Widget _errorAlert(String msg) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.bottom(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      msg,
      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
    ),
  );
}
