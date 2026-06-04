import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/case_card.dart';

class VetCasesScreen extends StatefulWidget {
  const VetCasesScreen({super.key});
  @override
  State<VetCasesScreen> createState() => _VetCasesScreenState();
}

class _VetCasesScreenState extends State<VetCasesScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchAllCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>();
    final filtered = cases.allCases.where((c) {
      if (_filter == 'Critical') return c.severity == 'critical';
      if (_filter == 'Urgent') return c.severity == 'urgent';
      if (_filter == 'Treated') return c.isResolved;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Animal Cases'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Critical', 'Urgent', 'Treated'].map((f) {
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.teal : AppColors.divider),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.white : AppColors.dark,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: cases.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filtered.isEmpty
                    ? const Center(child: Text('No cases found.', style: TextStyle(color: AppColors.gray)))
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: () => context.read<CaseProvider>().fetchAllCases(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => CaseCard(
                            caseModel: filtered[i],
                            onTap: () => Navigator.pushNamed(context, '/vet/case', arguments: filtered[i].id),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
