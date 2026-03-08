import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class DiffChange {
  final String taskId;
  final String field; // 'title' | 'description' | 'priority'
  final String oldValue;
  final String newValue;
  final String reason;

  const DiffChange({
    required this.taskId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.reason,
  });

  factory DiffChange.fromMap(Map<String, dynamic> data) {
    return DiffChange(
      taskId: data['taskId'] ?? '',
      field: data['field'] ?? '',
      oldValue: data['oldValue'] ?? '',
      newValue: data['newValue'] ?? '',
      reason: data['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'reason': reason,
    };
  }
}

class RecalibrationDiffModel {
  final String diffId;
  final String projectId;
  final String kbItemId;
  final String status; // 'pending_review' | 'accepted' | 'dismissed'
  final List<DiffChange> changes;
  final List<TaskModel> newTasks;
  final Timestamp? createdAt;

  const RecalibrationDiffModel({
    required this.diffId,
    required this.projectId,
    required this.kbItemId,
    this.status = 'pending_review',
    this.changes = const [],
    this.newTasks = const [],
    this.createdAt,
  });

  factory RecalibrationDiffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecalibrationDiffModel(
      diffId: doc.id,
      projectId: data['projectId'] ?? '',
      kbItemId: data['kbItemId'] ?? '',
      status: data['status'] ?? 'pending_review',
      changes: (data['changes'] as List<dynamic>?)
              ?.map((c) => DiffChange.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      newTasks: (data['newTasks'] as List<dynamic>?)
              ?.map((t) {
                final taskData = t as Map<String, dynamic>;
                return TaskModel(
                  taskId: taskData['taskId'] ?? '',
                  projectId: data['projectId'] ?? '',
                  parentId: taskData['parentId'],
                  level: taskData['level'] ?? 1,
                  title: taskData['title'] ?? '',
                  description: taskData['description'] ?? '',
                  priority: taskData['priority'] ?? 'medium',
                  status: 'todo',
                  aiGenerated: true,
                  lockedFromRecalib: false,
                  order: taskData['order'] ?? 0,
                );
              })
              .toList() ??
          [],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'kbItemId': kbItemId,
      'status': status,
      'changes': changes.map((c) => c.toMap()).toList(),
      'newTasks': newTasks.map((t) => t.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  bool get isPending => status == 'pending_review';
  bool get isAccepted => status == 'accepted';
  bool get isDismissed => status == 'dismissed';
  int get changeCount => changes.length;
  int get newTaskCount => newTasks.length;
}
