import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/case_card.dart';

class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchMyCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>();
    final filtered = cases.myCases.where((c) {
      if (_filter == 'All') return true;
      if (_filter == 'Active') return !c.isResolved;
      if (_filter == 'Resolved') return c.isResolved;
      if (_filter == 'Critical') return c.isCritical;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Active', 'Resolved', 'Critical'].map((f) {
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.teal : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.teal : AppColors.lightGray),
                      ),
                      child: Text(f,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                              color: active ? Colors.white : AppColors.dark)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),

          Expanded(
            child: cases.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🐾', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            const Text('No reports yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark)),
                            const SizedBox(height: 6),
                            const Text('Report an animal in need!', style: TextStyle(color: AppColors.gray)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: () => context.read<CaseProvider>().fetchMyCases(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => CaseCard(
                            caseModel: filtered[i],
                            onTap: () => Navigator.pushNamed(context, '/citizen/case', arguments: filtered[i].id),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
