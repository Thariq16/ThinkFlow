import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

/// Local edit state for a single task card
class TaskEditState {
  final String taskId;
  final String projectId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final bool lockedFromRecalib;
  final bool isDirty;
  final bool isSaving;
  final String? error;

  const TaskEditState({
    required this.taskId,
    required this.projectId,
    this.title = '',
    this.description = '',
    this.priority = 'medium',
    this.status = 'todo',
    this.lockedFromRecalib = false,
    this.isDirty = false,
    this.isSaving = false,
    this.error,
  });

  TaskEditState copyWith({
    String? title,
    String? description,
    String? priority,
    String? status,
    bool? lockedFromRecalib,
    bool? isDirty,
    bool? isSaving,
    String? error,
  }) {
    return TaskEditState(
      taskId: taskId,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      lockedFromRecalib: lockedFromRecalib ?? this.lockedFromRecalib,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'lockedFromRecalib': lockedFromRecalib,
    };
  }
}

/// StateNotifier implementing the optimistic update pattern:
/// 1. Update local Riverpod state immediately (no await)
/// 2. Persist to Firestore in background
/// 3. Rollback on failure
class TaskEditNotifier extends StateNotifier<TaskEditState> {
  final FirestoreService _firestore;

  TaskEditNotifier({
    required FirestoreService firestore,
    required TaskEditState initialState,
  })  : _firestore = firestore,
        super(initialState);

  /// Step 1: Update local state immediately (no await)
  void updateTitle(String newTitle) {
    state = state.copyWith(title: newTitle, isDirty: true);
  }

  void updateDescription(String newDescription) {
    state = state.copyWith(description: newDescription, isDirty: true);
  }

  void updatePriority(String newPriority) {
    state = state.copyWith(priority: newPriority, isDirty: true);
  }

  void updateStatus(String newStatus) {
    state = state.copyWith(status: newStatus, isDirty: true);
  }

  void toggleLock() {
    state = state.copyWith(
      lockedFromRecalib: !state.lockedFromRecalib,
      isDirty: true,
    );
  }

  /// Step 2: Persist to Firestore — rollback on failure
  Future<void> save() async {
    if (!state.isDirty) return;

    final previous = state;
    state = state.copyWith(isSaving: true, error: null);

    try {
      await _firestore.updateTask(
        state.projectId,
        state.taskId,
        state.toMap(),
      );
      state = state.copyWith(isSaving: false, isDirty: false);
    } catch (e) {
      // Rollback to previous state on failure
      state = previous.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }
}

/// Family provider — creates a TaskEditNotifier for each taskId
/// Requires initial state to be set from the task data
final taskEditNotifierProvider = StateNotifierProvider.family<TaskEditNotifier,
    TaskEditState, ({String taskId, String projectId})>((ref, params) {
  final firestore = ref.watch(firestoreServiceProvider);
  return TaskEditNotifier(
    firestore: firestore,
    initialState: TaskEditState(
      taskId: params.taskId,
      projectId: params.projectId,
    ),
  );
});
