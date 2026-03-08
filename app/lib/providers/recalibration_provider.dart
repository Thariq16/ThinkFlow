import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recalibration_diff_model.dart';
import '../services/functions_service.dart';
import '../services/firestore_service.dart';

/// Recalibration state
class RecalibState {
  final bool isLoading;
  final String? diffId;
  final int? changeCount;
  final int? newTaskCount;
  final String? error;

  const RecalibState({
    this.isLoading = false,
    this.diffId,
    this.changeCount,
    this.newTaskCount,
    this.error,
  });

  RecalibState copyWith({
    bool? isLoading,
    String? diffId,
    int? changeCount,
    int? newTaskCount,
    String? error,
  }) {
    return RecalibState(
      isLoading: isLoading ?? this.isLoading,
      diffId: diffId ?? this.diffId,
      changeCount: changeCount ?? this.changeCount,
      newTaskCount: newTaskCount ?? this.newTaskCount,
      error: error,
    );
  }
}

/// AsyncNotifier for recalibration — calls recalibrateProject Cloud Function
/// Holds the returned diffId for navigation to the diff review screen
class RecalibrationNotifier extends StateNotifier<RecalibState> {
  final FunctionsService _functions;

  RecalibrationNotifier({
    required FunctionsService functions,
  })  : _functions = functions,
        super(const RecalibState());

  /// Trigger recalibration
  Future<void> recalibrate({
    required String projectId,
    required String kbItemId,
  }) async {
    state = const RecalibState(isLoading: true);

    try {
      final result = await _functions.recalibrateProject(
        projectId: projectId,
        kbItemId: kbItemId,
      );

      state = RecalibState(
        isLoading: false,
        diffId: result['diffId'] as String?,
        changeCount: result['changeCount'] as int?,
        newTaskCount: result['newTaskCount'] as int?,
      );
    } catch (e) {
      state = RecalibState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Accept selected changes from a diff
  Future<void> acceptDiff({
    required String projectId,
    required String diffId,
    required List<String> acceptedChangeIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _functions.acceptRecalibDiff(
        projectId: projectId,
        diffId: diffId,
        acceptedChangeIds: acceptedChangeIds,
      );
      state = const RecalibState(); // Reset after acceptance
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reset state
  void reset() {
    state = const RecalibState();
  }
}

/// Recalibration provider
final recalibrationProvider =
    StateNotifierProvider<RecalibrationNotifier, RecalibState>((ref) {
  return RecalibrationNotifier(
    functions: FunctionsService(),
  );
});

/// Streams pending diffs for a project
final pendingDiffsProvider =
    StreamProvider.family<List<RecalibrationDiffModel>, String>(
        (ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamPendingDiffs(projectId);
});
