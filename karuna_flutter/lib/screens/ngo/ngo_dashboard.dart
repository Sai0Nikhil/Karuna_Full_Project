import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/case_card.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchAllCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cases = context.watch<CaseProvider>();

    final critical = cases.allCases.where((c) => c.severity == 'critical').toList();
    final active = cases.allCases.where((c) => !c.isResolved).toList();
    final resolved = cases.allCases.where((c) => c.isResolved).toList();
    final unassigned = cases.allCases.where((c) => !c.isAssigned && !c.isResolved).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => context.read<CaseProvider>().fetchAllCases(),
        child: CustomScrollView(
          slivers: [
            // NGO App bar
            SliverAppBar(
              expandedHeight: 80,
              pinned: true,
              backgroundColor: AppColors.navy,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              const Text('🐾 ', style: TextStyle(fontSize: 18)),
                              const Text('Karuṇā NGO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ]),
                            Text('Good morning, ${auth.user?.name.split(' ').first ?? 'NGO'} 👋',
                                style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_outlined, color: Colors.white),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _statCard('${active.length}', 'Active Cases', AppColors.urgent),
                        _statCard('${critical.length}', 'Critical', AppColors.critical),
                        _statCard('${resolved.length}', 'Resolved', AppColors.resolved),
                        _statCard('${unassigned.length}', 'Unassigned', AppColors.active),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Priority cases
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Priority Cases', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All', style: TextStyle(color: AppColors.teal, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (cases.loading)
              const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.teal))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final priorityCases = [...critical, ...unassigned].take(5).toList();
                      if (i >= priorityCases.length) return null;
                      final c = priorityCases[i];
                      return CaseCard(
                        caseModel: c,
                        onTap: () => Navigator.pushNamed(context, '/ngo/case', arguments: c.id),
                      );
                    },
                    childCount: [...critical, ...unassigned].take(5).length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
        ],
      ),
    );
  }
}
