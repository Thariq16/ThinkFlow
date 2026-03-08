import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String projectId;
  final String uid;
  final String title;
  final String description;
  final String voiceTranscript;
  final String status; // 'active' | 'archived'
  final int taskCount;
  final int completedCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const ProjectModel({
    required this.projectId,
    required this.uid,
    required this.title,
    this.description = '',
    this.voiceTranscript = '',
    this.status = 'active',
    this.taskCount = 0,
    this.completedCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      projectId: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      voiceTranscript: data['voiceTranscript'] ?? '',
      status: data['status'] ?? 'active',
      taskCount: data['taskCount'] ?? 0,
      completedCount: data['completedCount'] ?? 0,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'voiceTranscript': voiceTranscript,
      'status': status,
      'taskCount': taskCount,
      'completedCount': completedCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProjectModel copyWith({
    String? title,
    String? description,
    String? voiceTranscript,
    String? status,
    int? taskCount,
    int? completedCount,
  }) {
    return ProjectModel(
      projectId: projectId,
      uid: uid,
      title: title ?? this.title,
      description: description ?? this.description,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      status: status ?? this.status,
      taskCount: taskCount ?? this.taskCount,
      completedCount: completedCount ?? this.completedCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  double get completionProgress =>
      taskCount > 0 ? completedCount / taskCount : 0.0;
}
