import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

/// StreamProvider.family parameterised by projectId
/// Real-time task tree for a given project — rebuilt when project changes
/// Subscribes to the Firestore subcollection: projects/{projectId}/tasks
final tasksProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamTasks(projectId);
});
