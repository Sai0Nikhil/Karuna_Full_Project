import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../services/donation_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int? _selectedAmount;
  final _customCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  int? _caseId;

  final _presets = [50, 100, 250, 500, 1000];

  int get _amount => _selectedAmount ?? (int.tryParse(_customCtrl.text) ?? 0);

  @override
  void dispose() {
    _customCtrl.dispose(); _nameCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _donate() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an amount')),
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cases = context.read<CaseProvider>().openCases;
      final targetCaseId = _caseId ?? (cases.isNotEmpty ? cases.first.id : 1);
      await DonationService.donate(
        caseId: targetCaseId,
        donorName: _nameCtrl.text.trim(),
        amountInr: _amount,
        message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      );
      setState(() { _loading = false; _success = true; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.critical),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donate'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.teal, AppColors.tealDark]),
              ),
              child: const Column(
                children: [
                  Text('💝', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('Your donation saves lives', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Every contribution helps injured animals', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose an Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: _presets.map((amt) {
                      final active = _selectedAmount == amt;
                      return GestureDetector(
                        onTap: () => setState(() { _selectedAmount = amt; _customCtrl.clear(); }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: active ? AppColors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: active ? AppColors.teal : AppColors.lightGray),
                          ),
                          alignment: Alignment.center,
                          child: Text('₹$amt',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                  color: active ? Colors.white : AppColors.dark)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _selectedAmount = null),
                    decoration: const InputDecoration(
                      labelText: 'Custom Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee, color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message (Optional)',
                      prefixIcon: Icon(Icons.message_outlined, color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: _amount > 0 ? 'Donate ₹$_amount 💝' : 'Donate',
                    loading: _loading,
                    onPressed: _donate,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('🔒 Secure payment · 80G tax exemption eligible',
                        style: TextStyle(fontSize: 11, color: AppColors.gray)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.resolvedBg, borderRadius: BorderRadius.circular(50)),
                child: const Center(child: Text('💝', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 24),
              const Text('Thank You! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.dark)),
              const SizedBox(height: 10),
              Text('Your donation of ₹$_amount has been recorded. You\'re helping save a life!',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.gray)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() { _success = false; _selectedAmount = null; }),
                child: const Text('Donate Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
