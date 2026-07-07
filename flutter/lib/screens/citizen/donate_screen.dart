import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../services/donation_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';
import '../../utils/pdf_ledger_helper.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _caseId = args;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose(); _nameCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  void _startCheckout() {
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

    String paymentMethod = 'UPI';
    String selectedUpiApp = 'Google Pay';
    String paymentState = 'idle'; // idle, processing, pin, verifying, success

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Razorpay-style)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2438),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🐾 KARUNA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Secure Sandbox Checkout', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pay Amount', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('₹$_amount', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (paymentState == 'idle') ...[
                  const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),

                  // UPI Selector
                  _buildPaymentOption(
                    title: 'UPI (Google Pay, PhonePe)',
                    subtitle: 'Pay instantly using any UPI app',
                    icon: Icons.mobile_screen_share,
                    selected: paymentMethod == 'UPI',
                    onTap: () => setSheetState(() => paymentMethod = 'UPI'),
                  ),
                  const SizedBox(height: 8),

                  // Card Selector
                  _buildPaymentOption(
                    title: 'Card (Credit/Debit)',
                    subtitle: 'Visa, MasterCard, RuPay supported',
                    icon: Icons.credit_card,
                    selected: paymentMethod == 'Card',
                    onTap: () => setSheetState(() => paymentMethod = 'Card'),
                  ),
                  const SizedBox(height: 8),

                  // Netbanking Selector
                  _buildPaymentOption(
                    title: 'Netbanking',
                    subtitle: 'All major Indian banks',
                    icon: Icons.account_balance,
                    selected: paymentMethod == 'Netbanking',
                    onTap: () => setSheetState(() => paymentMethod = 'Netbanking'),
                  ),

                  if (paymentMethod == 'UPI') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Google Pay', 'PhonePe', 'Paytm'].map((app) {
                        final active = selectedUpiApp == app;
                        return ElevatedButton(
                          onPressed: () => setSheetState(() => selectedUpiApp = app),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: active ? AppColors.teal : Colors.grey[200],
                            foregroundColor: active ? Colors.white : Colors.black87,
                            elevation: 0,
                          ),
                          child: Text(app, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setSheetState(() => paymentState = 'processing');
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (paymentMethod == 'UPI') {
                            setSheetState(() => paymentState = 'pin');
                          } else {
                            setSheetState(() => paymentState = 'verifying');
                          }
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            setSheetState(() => paymentState = 'success');
                            Future.delayed(const Duration(milliseconds: 1200), () async {
                              Navigator.pop(ctx);
                              _executeDonate(paymentMethod);
                            });
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5266EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Pay ₹$_amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (paymentState == 'processing') ...[
                          const CircularProgressIndicator(color: Color(0xFF5266EB)),
                          const SizedBox(height: 16),
                          const Text('Processing payment...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Do not close the application', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ] else if (paymentState == 'pin') ...[
                          const Icon(Icons.lock_outline, size: 48, color: Color(0xFF5266EB)),
                          const SizedBox(height: 16),
                          Text('Confirming secure UPI PIN on $selectedUpiApp...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Enter PIN on request prompt', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ] else if (paymentState == 'verifying') ...[
                          const CircularProgressIndicator(color: Colors.amber),
                          const SizedBox(height: 16),
                          const Text('Verifying secure transaction...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Connecting to banking secure portal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ] else if (paymentState == 'success') ...[
                          const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('Transaction Successful!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Payment logged in immutable ledger', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF5266EB) : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF5266EB) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? const Color(0xFF5266EB) : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF5266EB) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeDonate(String method) async {
    setState(() => _loading = true);
    try {
      final cases = context.read<CaseProvider>().openCases;
      final targetCaseId = _caseId ?? (cases.isNotEmpty ? cases.first.id : 1);
      await DonationService.donate(
        caseId: targetCaseId,
        donorName: _nameCtrl.text.trim(),
        amountInr: _amount,
        message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        paymentMethod: method,
        billOffsetDetails: 'Case #$targetCaseId Vet Treatment Offset',
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
                    onPressed: _startCheckout,
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final cases = context.read<CaseProvider>().openCases;
                  final targetCase = cases.firstWhere(
                    (c) => c.id == (_caseId ?? (cases.isNotEmpty ? cases.first.id : 1)),
                    orElse: () => cases.first,
                  );
                  await PdfLedgerHelper.generateAndPrintLedger(targetCase);
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF Ledger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 42),
                ),
              ),
              const SizedBox(height: 12),
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
