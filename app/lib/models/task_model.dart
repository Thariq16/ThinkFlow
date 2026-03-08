import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String projectId;
  final String? parentId; // null = Level 1 epic
  final int level; // 1 = epic, 2 = subtask
  final String title;
  final String description;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'todo' | 'in_progress' | 'done'
  final bool aiGenerated;
  final bool lockedFromRecalib;
  final int order;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const TaskModel({
    required this.taskId,
    required this.projectId,
    this.parentId,
    required this.level,
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.status = 'todo',
    this.aiGenerated = true,
    this.lockedFromRecalib = false,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      taskId: doc.id,
      projectId: data['projectId'] ?? '',
      parentId: data['parentId'],
      level: data['level'] ?? 1,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'todo',
      aiGenerated: data['aiGenerated'] ?? true,
      lockedFromRecalib: data['lockedFromRecalib'] ?? false,
      order: data['order'] ?? 0,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'parentId': parentId,
      'level': level,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'aiGenerated': aiGenerated,
      'lockedFromRecalib': lockedFromRecalib,
      'order': order,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TaskModel copyWith({
    String? parentId,
    int? level,
    String? title,
    String? description,
    String? priority,
    String? status,
    bool? aiGenerated,
    bool? lockedFromRecalib,
    int? order,
  }) {
    return TaskModel(
      taskId: taskId,
      projectId: projectId,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      lockedFromRecalib: lockedFromRecalib ?? this.lockedFromRecalib,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isEpic => level == 1;
  bool get isSubtask => level == 2;
  bool get isDone => status == 'done';
  bool get isIncomplete => status != 'done';
}
