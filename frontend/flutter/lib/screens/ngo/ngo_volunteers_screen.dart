import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../utils/app_colors.dart';

/// NGO Volunteers management screen — list, availability toggle.
class NgoVolunteersScreen extends StatefulWidget {
  const NgoVolunteersScreen({super.key});

  @override
  State<NgoVolunteersScreen> createState() => _NgoVolunteersScreenState();
}

class _NgoVolunteersScreenState extends State<NgoVolunteersScreen> {
  List<Map<String, dynamic>> _volunteers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('${ApiConfig.baseUrl}/volunteers');
      List<dynamic> raw;
      if (data is Map && data.containsKey('content')) {
        raw = data['content'] as List<dynamic>;
      } else if (data is List) {
        raw = data;
      } else {
        raw = [];
      }
      setState(() {
        _volunteers = raw.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleAvailability(int id, bool current) async {
    try {
      await ApiService.put(
        '${ApiConfig.baseUrl}/volunteers/$id/availability',
        {'available': !current},
      );
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        title: Text('Volunteers (${_volunteers.length})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.critical),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.gray)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _volunteers.isEmpty
                  ? const Center(
                      child: Text('No volunteers registered yet.',
                          style: TextStyle(color: AppColors.gray, fontSize: 15)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.teal,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _volunteers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final v = _volunteers[i];
                          final available = v['available'] as bool? ?? false;
                          final name = v['user']?['name'] ?? v['name'] ?? 'Volunteer #${v['id']}';
                          final skills = (v['skills'] as List?)?.join(', ') ?? 'General';
                          final activeCases = v['activeCasesCount'] ?? 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: available
                                      ? AppColors.resolved.withOpacity(0.4)
                                      : AppColors.divider),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    available ? AppColors.tealBg : AppColors.divider,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                  style: TextStyle(
                                      color: available
                                          ? AppColors.teal
                                          : AppColors.gray,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Skills: $skills',
                                      style: const TextStyle(
                                          color: AppColors.gray, fontSize: 12)),
                                  Text('Active cases: $activeCases',
                                      style: const TextStyle(
                                          color: AppColors.gray, fontSize: 12)),
                                ],
                              ),
                              trailing: Switch(
                                value: available,
                                activeColor: AppColors.teal,
                                onChanged: (_) => _toggleAvailability(
                                    v['id'] as int, available),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
