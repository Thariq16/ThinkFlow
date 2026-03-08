import 'package:cloud_firestore/cloud_firestore.dart';

class KbItemModel {
  final String kbId;
  final String projectId;
  final String type; // 'pdf' | 'url' | 'text'
  final String label;
  final String? storageRef; // Firebase Storage path for PDFs
  final String? sourceUrl; // For URL type
  final String extractedText;
  final String status; // 'processing' | 'ready' | 'error'
  final Timestamp? processedAt;
  final Timestamp? createdAt;

  const KbItemModel({
    required this.kbId,
    required this.projectId,
    required this.type,
    required this.label,
    this.storageRef,
    this.sourceUrl,
    this.extractedText = '',
    this.status = 'processing',
    this.processedAt,
    this.createdAt,
  });

  factory KbItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KbItemModel(
      kbId: doc.id,
      projectId: data['projectId'] ?? '',
      type: data['type'] ?? 'text',
      label: data['label'] ?? '',
      storageRef: data['storageRef'],
      sourceUrl: data['sourceUrl'],
      extractedText: data['extractedText'] ?? '',
      status: data['status'] ?? 'processing',
      processedAt: data['processedAt'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'type': type,
      'label': label,
      'storageRef': storageRef,
      'sourceUrl': sourceUrl,
      'extractedText': extractedText,
      'status': status,
      'processedAt': processedAt,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  KbItemModel copyWith({
    String? label,
    String? extractedText,
    String? status,
    Timestamp? processedAt,
  }) {
    return KbItemModel(
      kbId: kbId,
      projectId: projectId,
      type: type,
      label: label ?? this.label,
      storageRef: storageRef,
      sourceUrl: sourceUrl,
      extractedText: extractedText ?? this.extractedText,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt,
    );
  }

  bool get isReady => status == 'ready';
  bool get isProcessing => status == 'processing';
  bool get hasError => status == 'error';
}
