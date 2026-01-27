import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// Core
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';

// Models
import '../models/warehouse_document.dart';

class DocumentsFeedPage extends StatelessWidget {
  const DocumentsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // [PROTOCOL-VISUAL-1] Access Sovereign Theme Extensions
    final proColors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      appBar: AppBar(
        title: Text(
          "Документооборот",
          style: GoogleFonts.inter(
            color: proColors.contentPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20, // Standard App Bar Title Size
          ),
        ),
        backgroundColor: proColors.surfaceLow.withValues(
          alpha: 0.95,
        ), // Sovereign Blur Base
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        // Standardized padding for leading icons if needed later
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warehouse_documents')
            .orderBy('uploadTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: proColors.accentAction),
            );
          }

          final docs = snapshot.data!.docs
              .map(
                (d) => WarehouseDocument.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded, // Better empty state icon
                    size: 64,
                    color: proColors.contentTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: Dimens.gapL), // 16
                  Text(
                    "Нет активных документов",
                    style: GoogleFonts.inter(
                      color: proColors.neutralGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            // [PROTOCOL-VISUAL-1] Standard Screen Padding
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.gapXl, // 24
              vertical: Dimens.gapL, // 16
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildDocCard(docs[index], proColors, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocCard(
    WarehouseDocument doc,
    SkladColors proColors,
    bool isDark,
  ) {
    // Color coding logic
    Color typeColor = doc.type == DocumentType.pot
        ? proColors.success
        : proColors.warning;

    String typeLabel = doc.type == DocumentType.pot
        ? "ПОТ (Приход)"
        : "РОТ (Расход)";

    return Container(
      // [PROTOCOL-VISUAL-1] Standard Spacing Between Cards
      margin: const EdgeInsets.only(bottom: Dimens.gapM), // 12
      padding: const EdgeInsets.all(Dimens.paddingCard), // 16
      decoration: BoxDecoration(
        color: proColors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
        // Left accent border logic retained but refined
        border: Border(
          left: BorderSide(color: typeColor, width: 4),
          // Add subtle border around rest for depth if needed, relying on shadow for now
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapS, // 8
                  vertical: 4, // 4 (half gapS)
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimens.radiusS), // 8
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.inter(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM HH:mm').format(doc.uploadTime),
                style: GoogleFonts.inter(
                  color: proColors.neutralGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.gapM), // 12
          // Route info
          Row(
            children: [
              Icon(
                Icons.warehouse_rounded,
                size: 18, // Slightly larger for visibility
                color: proColors.neutralGray,
              ),
              const SizedBox(width: Dimens.gapS), // 8
              Text(
                doc.sourceStorage,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: proColors.contentPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapS,
                ), // 8
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: proColors.contentTertiary,
                ),
              ),
              Text(
                doc.destinationStorage,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: proColors.contentPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimens.gapM), // 12
          Divider(height: 1, color: proColors.divider),
          const SizedBox(height: Dimens.gapM), // 12
          // Uploader Info
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: proColors.surfaceContainer,
                backgroundImage: doc.uploaderPhotoUrl != null
                    ? NetworkImage(doc.uploaderPhotoUrl!)
                    : null,
                child: doc.uploaderPhotoUrl == null
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: proColors.contentSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: Dimens.gapS), // 8
              Text(
                "Загрузил: ${doc.uploaderName}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: proColors.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "${doc.itemsCount} поз.",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: proColors.accentAction,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
