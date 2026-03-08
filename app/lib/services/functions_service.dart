import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Process voice recording — transcribe + decompose into task tree
  /// Input: { audioBase64: string, mimeType: string, projectId?: string }
  /// Output: { projectId: string, transcript: string, tasks: TaskTree }
  Future<Map<String, dynamic>> processVoice({
    required String audioBase64,
    required String mimeType,
    String? projectId,
  }) async {
    final callable = _functions.httpsCallable('processVoice');
    final result = await callable.call({
      'audioBase64': audioBase64,
      'mimeType': mimeType,
      if (projectId != null) 'projectId': projectId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Generate subtasks for an epic using Gemini Flash
  /// Input: { projectId, epicId, epicTitle, epicDescription }
  /// Output: { subtasks: SubTask[] }
  Future<Map<String, dynamic>> generateSubtasks({
    required String projectId,
    required String epicId,
    required String epicTitle,
    required String epicDescription,
  }) async {
    final callable = _functions.httpsCallable('generateSubtasks');
    final result = await callable.call({
      'projectId': projectId,
      'epicId': epicId,
      'epicTitle': epicTitle,
      'epicDescription': epicDescription,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Ingest a knowledge base item (PDF, URL, or text)
  /// Input: { projectId, type, storageRef?, url?, text?, label }
  /// Output: { kbItemId: string, status: string }
  Future<Map<String, dynamic>> ingestKbItem({
    required String projectId,
    required String type,
    required String label,
    String? storageRef,
    String? url,
    String? text,
  }) async {
    final callable = _functions.httpsCallable('ingestKbItem');
    final result = await callable.call({
      'projectId': projectId,
      'type': type,
      'label': label,
      if (storageRef != null) 'storageRef': storageRef,
      if (url != null) 'url': url,
      if (text != null) 'text': text,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Trigger project recalibration against KB item
  /// Input: { projectId, kbItemId }
  /// Output: { diffId, changeCount, newTaskCount }
  Future<Map<String, dynamic>> recalibrateProject({
    required String projectId,
    required String kbItemId,
  }) async {
    final callable = _functions.httpsCallable('recalibrateProject');
    final result = await callable.call({
      'projectId': projectId,
      'kbItemId': kbItemId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Accept selected changes from a recalibration diff
  /// Input: { projectId, diffId, acceptedChangeIds }
  /// Output: { updatedCount }
  Future<Map<String, dynamic>> acceptRecalibDiff({
    required String projectId,
    required String diffId,
    required List<String> acceptedChangeIds,
  }) async {
    final callable = _functions.httpsCallable('acceptRecalibDiff');
    final result = await callable.call({
      'projectId': projectId,
      'diffId': diffId,
      'acceptedChangeIds': acceptedChangeIds,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Create a Stripe Checkout session
  /// Input: { plan, successUrl, cancelUrl }
  /// Output: { checkoutUrl }
  Future<String> createCheckoutSession({
    required String plan,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call({
      'plan': plan,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    final data = Map<String, dynamic>.from(result.data);
    return data['checkoutUrl'] as String;
  }
}
