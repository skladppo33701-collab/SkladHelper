import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/core/constants/dimens.dart'; // [PROTOCOL-VISUAL-1]
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';

class AssignmentCard extends ConsumerWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalReq = assignment.items.fold(
      0.0,
      (sum, item) => sum + item.requiredQty,
    );
    final totalScanned = assignment.items.fold(
      0.0,
      (sum, item) => sum + item.scannedQty,
    );
    final progress = totalReq > 0
        ? (totalScanned / totalReq).clamp(0.0, 1.0)
        : 0.0;
    final isDone = assignment.status == AssignmentStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimens.gapM),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusL),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(Dimens.paddingCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDone
                            ? colors.success.withValues(alpha: 0.1)
                            : colors.accentAction.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimens.radiusS),
                      ),
                      child: Text(
                        assignment.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDone ? colors.success : colors.accentAction,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colors.neutralGray,
                        ),
                        const SizedBox(width: Dimens.gapXs),
                        Text(
                          DateFormat(
                            'dd MMM, HH:mm',
                          ).format(assignment.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: Dimens.gapM),

                // [PROTOCOL-VISUAL-2] Reflow Hardening: Text scaling support
                Text(
                  assignment.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: Dimens.gapL),

                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimens.radiusS),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation(
                            isDone ? colors.success : colors.accentAction,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimens.gapM),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? colors.success : colors.accentAction,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
