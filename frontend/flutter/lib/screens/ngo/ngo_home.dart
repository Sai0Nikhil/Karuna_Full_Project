import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../services/websocket_service.dart';
import '../../utils/app_colors.dart';
import 'ngo_dashboard.dart';
import 'ngo_case_list.dart';
import 'ngo_analytics_screen.dart';
import 'ngo_volunteers_screen.dart';

class NgoHome extends StatefulWidget {
  const NgoHome({super.key});

  @override
  State<NgoHome> createState() => _NgoHomeState();
}

class _NgoHomeState extends State<NgoHome> {
  int _tab = 0;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  final List<String> _liveAlerts = [];

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().loadCases();
      _connectWebSocket();
    });
  }

  void _connectWebSocket() {
    WebSocketService.instance.connect();
    _wsSub = WebSocketService.instance.stream.listen((event) {
      final type = event['type'] as String? ?? '';
      final payload = event['payload'] as Map<String, dynamic>? ?? {};
      if (['CASE_CREATED', 'CASE_UPDATED', 'CASE_ASSIGNED'].contains(type)) {
        // Refresh case list
        if (mounted) context.read<CaseProvider>().loadCases();
        // Show live alert banner
        final title = payload['title'] ?? payload['species'] ?? 'Animal case';
        final alert = '🚨 $type: $title';
        setState(() {
          _liveAlerts.add(alert);
          if (_liveAlerts.length > 5) _liveAlerts.removeAt(0);
        });
        _showLiveBanner(alert);
      }
    });
  }

  void _showLiveBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: const [
          NgoDashboard(),
          NgoCaseList(),
          NgoAnalyticsScreen(),
          NgoVolunteersScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.tealLight,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.teal),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: AppColors.teal),
            label: 'All Cases',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.teal),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.teal),
            label: 'Volunteers',
          ),
        ],
      ),
    );
  }
}
