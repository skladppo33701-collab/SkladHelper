import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import '../models/warehouse_document.dart';

class DocumentsFeedPage extends StatelessWidget {
  const DocumentsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      appBar: AppBar(
        title: const Text("Документооборот"),
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warehouse_documents')
            .orderBy('uploadTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
              child: Text(
                "Нет активных документов",
                style: TextStyle(color: proColors.neutralGray),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    // Color coding for document types
    Color typeColor = doc.type == DocumentType.pot
        ? proColors.success
        : proColors.warning;
    String typeLabel = doc.type == DocumentType.pot
        ? "ПОТ (Приход)"
        : "РОТ (Расход)";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: proColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: typeColor, width: 4)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM HH:mm').format(doc.uploadTime),
                style: TextStyle(color: proColors.neutralGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route info
          Row(
            children: [
              Icon(Icons.warehouse, size: 16, color: proColors.neutralGray),
              const SizedBox(width: 8),
              Text(
                doc.sourceStorage,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              ),
              Text(
                doc.destinationStorage,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Uploader Info
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: doc.uploaderPhotoUrl != null
                    ? NetworkImage(doc.uploaderPhotoUrl!)
                    : null,
                child: doc.uploaderPhotoUrl == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                "Загрузил: ${doc.uploaderName}",
                style: TextStyle(fontSize: 12, color: proColors.neutralGray),
              ),
              const Spacer(),
              Text(
                "${doc.itemsCount} поз.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: proColors.accentAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
