import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class PainAssessmentScreen extends StatefulWidget {
  final String breed;
  final String species;

  const PainAssessmentScreen({
    super.key,
    required this.breed,
    required this.species,
  });

  @override
  State<PainAssessmentScreen> createState() => _PainAssessmentScreenState();
}

class _PainAssessmentScreenState extends State<PainAssessmentScreen> {
  // GCPS selection indices
  int _gcps1 = 0;
  int _gcps2 = 0;
  int _gcps3 = 0;
  int _gcps4 = 0;

  // Form fields
  final _weightController = TextEditingController();
  final _tempController = TextEditingController();
  final _hrController = TextEditingController();
  final _breedController = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _breedController.text = widget.breed;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _tempController.dispose();
    _hrController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _assessPain() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final double? weight = double.tryParse(_weightController.text);
      final double? temp = double.tryParse(_tempController.text);
      final double? hr = double.tryParse(_hrController.text);

      final payload = <String, dynamic>{
        'breed': _breedController.text,
        'species': widget.species,
        'sex': 'unknown_sex',
        'neuterStatus': 'unknown_status',
        'gcps1': _gcps1,
        'gcps2': _gcps2,
        'gcps3': _gcps3,
        'gcps4': _gcps4,
        if (weight != null) 'weight': weight,
        if (temp != null) 'temperature': temp,
        if (hr != null) 'heartRate': hr,
      };

      final data = await ApiService.post(ApiConfig.aiPainIndex(), payload);
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _painColor(String? level) {
    if (level == null) return AppColors.gray;
    switch (level.toLowerCase()) {
      case 'severe':
        return AppColors.critical;
      case 'moderate':
        return AppColors.urgent;
      case 'mild':
      default:
        return AppColors.resolved;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Pain Index Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🐕 Glasgow Pain Scale (GCPS)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropdownRow(
                    label: '1. Kennel Behaviour / Posture:',
                    value: _gcps1,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Quiet (0)')),
                      DropdownMenuItem(value: 1, child: Text('Crying / Whimpering (1)')),
                    ],
                    onChanged: (v) => setState(() => _gcps1 = v ?? 0),
                  ),
                  const Divider(),
                  _dropdownRow(
                    label: '2. Response to Pain Site:',
                    value: _gcps2,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Ignoring Pain Site (0)')),
                      DropdownMenuItem(value: 1, child: Text('Looking at Pain Site (1)')),
                      DropdownMenuItem(value: 2, child: Text('Licking Pain Site (2)')),
                      DropdownMenuItem(value: 3, child: Text('Rubbing/Scratching (3)')),
                    ],
                    onChanged: (v) => setState(() => _gcps2 = v ?? 0),
                  ),
                  const Divider(),
                  _dropdownRow(
                    label: '3. Mobility / Walking:',
                    value: _gcps3,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Normal (0)')),
                      DropdownMenuItem(value: 1, child: Text('Lame (1)')),
                      DropdownMenuItem(value: 2, child: Text('Slow and Reluctant (2)')),
                      DropdownMenuItem(value: 3, child: Text('Stiff (3)')),
                      DropdownMenuItem(value: 4, child: Text('Refuses to move (4)')),
                    ],
                    onChanged: (v) => setState(() => _gcps3 = v ?? 0),
                  ),
                  const Divider(),
                  _dropdownRow(
                    label: '4. Touch Response (around site):',
                    value: _gcps4,
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
              '🩺 Clinical Vitals (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: [
                  TextField(
                    controller: _breedController,
                    decoration: const InputDecoration(
                      labelText: 'Breed',
                      icon: Icon(Icons.inventory, color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            icon: Icon(Icons.scale, color: AppColors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tempController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Temp (°C)',
                            hintText: 'e.g. 38.5',
                            icon: Icon(Icons.thermostat, color: AppColors.teal),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Heart Rate (bpm)',
                      hintText: 'e.g. 100',
                      icon: Icon(Icons.favorite, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.criticalBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.critical),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Calculate Pain Index'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _assessPain,
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null) ...[
              const Text(
                '🔮 Prediction Result',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _painColor(_result!['painLevel']).withOpacity(0.1),
                  border: Border.all(color: _painColor(_result!['painLevel'])),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pain Level: ${_result!['painLevel']?.toString().toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _painColor(_result!['painLevel']),
                          ),
                        ),
                        Text(
                          'Conf: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!['advice'] ?? '',
                      style: const TextStyle(fontSize: 14, color: AppColors.dark, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dropdownRow({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.gray,
          ),
        ),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
