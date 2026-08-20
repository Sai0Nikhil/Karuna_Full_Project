import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg.$1,
        style: TextStyle(
          color: cfg.$3,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color, Color) _config(String s) {
    switch (s.toLowerCase()) {
      case 'critical':   return ('🆘 Critical',   AppColors.criticalBg, AppColors.critical);
      case 'urgent':     return ('⚠️ Urgent',      AppColors.urgentBg,   AppColors.urgent);
      case 'reported':   return ('📋 Reported',    AppColors.inputBg,    AppColors.gray);
      case 'assigned':   return ('👤 Assigned',    AppColors.activeBg,   AppColors.active);
      case 'collected':  return ('🚑 Collected',   AppColors.urgentBg,   AppColors.urgent);
      case 'at_clinic':  return ('🏥 At Clinic',   AppColors.activeBg,   AppColors.active);
      case 'in_treatment': return ('💉 Treating',  AppColors.activeBg,   AppColors.active);
      case 'discharged': return ('✅ Discharged',  AppColors.resolvedBg, AppColors.resolved);
      case 'adopted':    return ('🐾 Adopted',     AppColors.resolvedBg, AppColors.resolved);
      case 'released':   return ('🌿 Released',    AppColors.resolvedBg, AppColors.resolved);
      default:           return (s,               AppColors.inputBg,    AppColors.gray);
    }
  }
}
