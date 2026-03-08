import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kb_item_model.dart';
import '../services/firestore_service.dart';

/// StreamProvider.family — real-time KB items for a project
final kbItemsProvider =
    StreamProvider.family<List<KbItemModel>, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamKbItems(projectId);
});
