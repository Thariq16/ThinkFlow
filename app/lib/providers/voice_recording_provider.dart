import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/functions_service.dart';

/// Voice recording status — strict state machine
/// idle → recording → processing → done → idle
///           ↘ error ↗
enum VoiceStatus { idle, recording, processing, done, error }

/// Voice recording state
class VoiceState {
  final VoiceStatus status;
  final String? transcript;
  final String? newProjectId;
  final String? errorMessage;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript,
    this.newProjectId,
    this.errorMessage,
  });

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    String? newProjectId,
    String? errorMessage,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      newProjectId: newProjectId ?? this.newProjectId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// StateNotifier managing the voice recording state machine
class VoiceRecordingNotifier extends StateNotifier<VoiceState> {
  final FunctionsService _functions;
  Uint8List? _audioBytes;

  VoiceRecordingNotifier({
    required FunctionsService functions,
  })  : _functions = functions,
        super(const VoiceState());

  /// idle → recording
  Future<void> startRecording() async {
    if (state.status != VoiceStatus.idle) return;
    state = const VoiceState(status: VoiceStatus.recording);
    // Audio recording is handled by the widget using the record package
    // The widget calls onAudioReady with the bytes when recording stops
  }

  /// Called by the widget when audio bytes are ready
  void setAudioBytes(Uint8List bytes) {
    _audioBytes = bytes;
  }

  /// recording → processing → done
  Future<void> stopAndProcess({String? existingProjectId}) async {
    if (state.status != VoiceStatus.recording) return;
    state = const VoiceState(status: VoiceStatus.processing);

    try {
      if (_audioBytes == null || _audioBytes!.isEmpty) {
        throw Exception('No audio data recorded');
      }

      // Convert audio bytes to base64 for the Cloud Function
      final audioBase64 = base64Encode(_audioBytes!);

      // Call processVoice Cloud Function
      final result = await _functions.processVoice(
        audioBase64: audioBase64,
        mimeType: 'audio/webm',
        projectId: existingProjectId,
      );

      state = VoiceState(
        status: VoiceStatus.done,
        transcript: result['transcript'] as String?,
        newProjectId: result['projectId'] as String?,
      );
    } catch (e) {
      state = VoiceState(
        status: VoiceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset to idle — from done or error
  void reset() {
    _audioBytes = null;
    state = const VoiceState(status: VoiceStatus.idle);
  }
}

/// Singleton services used by the notifier
final _functionsServiceProvider =
    Provider<FunctionsService>((ref) => FunctionsService());

/// VoiceRecordingProvider — StateNotifierProvider
final voiceRecordingProvider =
    StateNotifierProvider<VoiceRecordingNotifier, VoiceState>((ref) {
  return VoiceRecordingNotifier(
    functions: ref.watch(_functionsServiceProvider),
  );
});
