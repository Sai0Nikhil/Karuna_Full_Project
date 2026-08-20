import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final _presets = [100, 250, 500, 1000];

  // Hardcoded mockup recent donors list
  final _recentKindSouls = [
    {'name': 'Ananya Sharma', 'time': '2 hours ago', 'amount': 500, 'initials': 'AS', 'color': Color(0xFFD97706)},
    {'name': 'Rahul Kapoor', 'time': '5 hours ago', 'amount': 1000, 'initials': 'RK', 'color': Color(0xFF0F766E)},
    {'name': 'Anonymous Soul', 'time': 'Yesterday', 'amount': 250, 'initials': 'JD', 'color': Colors.grey},
  ];

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
    _customCtrl.dispose();
    _nameCtrl.dispose();
    _msgCtrl.dispose();
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
    String paymentState = 'idle';

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

                  _buildPaymentOption(
                    title: 'UPI (Google Pay, PhonePe)',
                    subtitle: 'Pay instantly using any UPI app',
                    icon: Icons.mobile_screen_share,
                    selected: paymentMethod == 'UPI',
                    onTap: () => setSheetState(() => paymentMethod = 'UPI'),
                  ),
                  const SizedBox(height: 8),

                  _buildPaymentOption(
                    title: 'Card (Credit/Debit)',
                    subtitle: 'Visa, MasterCard, RuPay supported',
                    icon: Icons.credit_card,
                    selected: paymentMethod == 'Card',
                    onTap: () => setSheetState(() => paymentMethod = 'Card'),
                  ),
                  const SizedBox(height: 8),

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
      setState(() {
        _loading = false;
        _success = true;
      });
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

    final casesProvider = context.watch<CaseProvider>();
    final allCases = casesProvider.cases;
    final activeCase = allCases.firstWhere(
      (c) => c.id == (_caseId ?? (allCases.isNotEmpty ? allCases.first.id : 1)),
      orElse: () => allCases.isNotEmpty
          ? allCases.first
          : DynamicCaseModelMock(), // fallback placeholder
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Karuṇā',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teal gradient banner card at top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help Save Animals 💛',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Every contribution brings a soul closer to recovery.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active animal case card with details
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                      border: Border.all(color: AppColors.divider, width: 1.0),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image thumbnail placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 82,
                            height: 82,
                            color: AppColors.tealLight.withOpacity(0.3),
                            child: activeCase.imageUrl != null
                                ? Image.network(activeCase.imageUrl!, fit: BoxFit.cover)
                                : const Center(child: Text('🐕', style: TextStyle(fontSize: 32))),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Animal info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    activeCase.title?.split(' with ').first ?? 'Sheru',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.criticalBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (activeCase.severity ?? 'CRITICAL').toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.critical,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Species: ${activeCase.species ?? "Indian Pariah"}',
                                style: GoogleFonts.inter(color: AppColors.gray, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeCase.probableCondition ?? 'Rescued from road accident',
                                style: GoogleFonts.inter(color: AppColors.gray, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Progress bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Amount Raised: ₹3,500 / ₹8,000',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                  Text(
                                    '44%',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  value: 0.44,
                                  color: AppColors.teal,
                                  backgroundColor: AppColors.divider,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select Amount Section
                  Text(
                    'Select Amount',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _presets.map((amt) {
                      final active = _selectedAmount == amt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('₹$amt'),
                            selected: active,
                            selectedColor: AppColors.teal,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: active ? Colors.white : AppColors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.divider),
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedAmount = amt;
                                  _customCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Custom Button
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Enter Custom Amount'),
                          content: TextField(
                            controller: _customCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.currency_rupee),
                              hintText: 'Enter amount in INR',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedAmount = null);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: Text(
                      _selectedAmount == null && _customCtrl.text.isNotEmpty
                          ? 'Custom: ₹${_customCtrl.text}'
                          : 'Custom',
                      style: GoogleFonts.inter(color: AppColors.dark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Donor details input
                  Text(
                    'Your Details',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message (Optional)',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Donate button
                  ElevatedButton(
                    onPressed: _startCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Donate Now 💛 ',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.favorite, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recent Kind Souls Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Kind Souls',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._recentKindSouls.map((soul) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: soul['color'] as Color,
                            child: Text(
                              soul['initials'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  soul['name'] as String,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  soul['time'] as String,
                                  style: GoogleFonts.inter(color: AppColors.gray, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${soul['amount']}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
      backgroundColor: const Color(0xFFF8FAFD),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.resolvedBg,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💝', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Thank You! 🎉',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your donation of ₹$_amount has been recorded. You\'re helping save a life!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray, height: 1.4),
              ),
              const SizedBox(height: 32),
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
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() {
                  _success = false;
                  _selectedAmount = null;
                }),
                child: const Text('Donate Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Temporary fallback class if cases provider is empty
class DynamicCaseModelMock {
  int get id => 1;
  String? get title => 'Sheru';
  String? get species => 'Indian Pariah';
  String? get severity => 'CRITICAL';
  String? get probableCondition => 'Rescued from a highway accident';
  String? get imageUrl => null;
}
