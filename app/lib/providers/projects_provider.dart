import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import 'auth_provider.dart';
import '../services/firestore_service.dart';

/// StreamProvider — real-time project list for the current user
/// Ordered by updatedAt descending
final projectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return firestoreService.streamProjects(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// StateProvider — holds the currently selected project ID
/// Null = show project list, non-null = show project detail
final activeProjectProvider = StateProvider<String?>((ref) => null);
