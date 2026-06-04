import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/case_card.dart';

class NgoCaseList extends StatefulWidget {
  const NgoCaseList({super.key});

  @override
  State<NgoCaseList> createState() => _NgoCaseListState();
}

class _NgoCaseListState extends State<NgoCaseList> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

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
    final query = _searchCtrl.text.toLowerCase();

    final filtered = cases.allCases.where((c) {
      final matchFilter = _filter == 'All' ||
          (_filter == 'Critical' && c.severity == 'critical') ||
          (_filter == 'Active' && !c.isResolved) ||
          (_filter == 'Resolved' && c.isResolved) ||
          (_filter == 'Unassigned' && !c.isAssigned);
      final matchSearch = query.isEmpty ||
          (c.species?.toLowerCase().contains(query) ?? false) ||
          (c.locationLabel?.toLowerCase().contains(query) ?? false) ||
          c.id.toString().contains(query);
      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Cases'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.read<CaseProvider>().fetchAllCases(),
            child: const Text('Refresh', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, species, location...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, color: AppColors.gray), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Critical', 'Active', 'Resolved', 'Unassigned'].map((f) {
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.teal : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$f (${_countFilter(cases.allCases, f)})',
                            style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.dark, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${filtered.length} cases', style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: cases.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filtered.isEmpty
                    ? const Center(child: Text('No cases found.', style: TextStyle(color: AppColors.gray)))
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: () => context.read<CaseProvider>().fetchAllCases(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => CaseCard(
                            caseModel: filtered[i],
                            onTap: () => Navigator.pushNamed(context, '/ngo/case', arguments: filtered[i].id),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  int _countFilter(List cases, String f) {
    if (f == 'All') return cases.length;
    if (f == 'Critical') return cases.where((c) => c.severity == 'critical').length;
    if (f == 'Active') return cases.where((c) => !c.isResolved).length;
    if (f == 'Resolved') return cases.where((c) => c.isResolved).length;
    if (f == 'Unassigned') return cases.where((c) => !c.isAssigned).length;
    return 0;
  }
}
