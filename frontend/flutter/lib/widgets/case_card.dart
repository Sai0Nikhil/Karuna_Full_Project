import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../utils/app_colors.dart';
import 'status_badge.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;

  const CaseCard({super.key, required this.caseModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animal emoji avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  caseModel.speciesEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#K${caseModel.id.toString().padLeft(3, '0')} · ${caseModel.species ?? 'Animal'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      StatusBadge(caseModel.severity ?? caseModel.status ?? 'reported'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caseModel.injuryType ?? caseModel.probableCondition ?? 'Reported case',
                    style: const TextStyle(fontSize: 12, color: AppColors.gray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.gray),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          caseModel.locationLabel ?? 'Location unknown',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
