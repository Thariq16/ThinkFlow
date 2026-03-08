import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/kb_item_model.dart';
import '../models/recalibration_diff_model.dart';
import '../models/user_model.dart';

/// Singleton FirestoreService provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Operations ───────────────────────────────────────────────

  /// Stream user document for the given UID
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Get user document once
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ─── Project Operations ────────────────────────────────────────────

  /// Stream all projects for a user, ordered by updatedAt desc
  Stream<List<ProjectModel>> streamProjects(String uid) {
    return _db
        .collection('projects')
        .where('uid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single project
  Future<ProjectModel?> getProject(String projectId) async {
    final doc = await _db.collection('projects').doc(projectId).get();
    if (!doc.exists) return null;
    return ProjectModel.fromFirestore(doc);
  }

  /// Create a new project
  Future<String> createProject(ProjectModel project) async {
    final docRef = _db.collection('projects').doc();
    final data = project.copyWith().toMap();
    await docRef.set(data);

    // Increment user's project count
    await _db.collection('users').doc(project.uid).update({
      'projectCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Update project fields
  Future<void> updateProject(
      String projectId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('projects').doc(projectId).update(data);
  }

  /// Delete project and all subcollections
  Future<void> deleteProject(String projectId, String uid) async {
    // Delete all tasks
    final tasks = await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .get();
    for (final doc in tasks.docs) {
      await doc.reference.delete();
    }

    // Delete all KB items
    final kbItems = await _db
        .collection('projects')
        .doc(projectId)
        .collection('kb_items')
        .get();
    for (final doc in kbItems.docs) {
      await doc.reference.delete();
    }

    // Delete all recalib diffs
    final diffs = await _db
        .collection('projects')
        .doc(projectId)
        .collection('recalib_diffs')
        .get();
    for (final doc in diffs.docs) {
      await doc.reference.delete();
    }

    // Delete the project document
    await _db.collection('projects').doc(projectId).delete();

    // Decrement user's project count
    await _db.collection('users').doc(uid).update({
      'projectCount': FieldValue.increment(-1),
    });
  }

  // ─── Task Operations ──────────────────────────────────────────────

  /// Stream all tasks for a project
  Stream<List<TaskModel>> streamTasks(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  /// Create a new task
  Future<String> createTask(String projectId, TaskModel task) async {
    final docRef = _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc();
    await docRef.set(task.toMap());

    // Update project task count
    await _db.collection('projects').doc(projectId).update({
      'taskCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Update a task — used by optimistic update pattern
  Future<void> updateTask(
      String projectId, String taskId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update(data);

    // If status changed to done, update completed count
    if (data.containsKey('status')) {
      if (data['status'] == 'done') {
        await _db.collection('projects').doc(projectId).update({
          'completedCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Delete a task
  Future<void> deleteTask(String projectId, String taskId) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .delete();

    await _db.collection('projects').doc(projectId).update({
      'taskCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── KB Item Operations ────────────────────────────────────────────

  /// Stream KB items for a project
  Stream<List<KbItemModel>> streamKbItems(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('kb_items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => KbItemModel.fromFirestore(doc)).toList());
  }

  // ─── Recalibration Diff Operations ─────────────────────────────────

  /// Stream pending diffs for a project
  Stream<List<RecalibrationDiffModel>> streamPendingDiffs(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('recalib_diffs')
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecalibrationDiffModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single diff
  Future<RecalibrationDiffModel?> getDiff(
      String projectId, String diffId) async {
    final doc = await _db
        .collection('projects')
        .doc(projectId)
        .collection('recalib_diffs')
        .doc(diffId)
        .get();
    if (!doc.exists) return null;
    return RecalibrationDiffModel.fromFirestore(doc);
  }
}
