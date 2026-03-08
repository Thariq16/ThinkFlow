import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/voice_recording_provider.dart';

class VoiceRecordButton extends ConsumerStatefulWidget {
  const VoiceRecordButton({super.key});

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final notifier = ref.read(voiceRecordingProvider.notifier);
    final state = ref.read(voiceRecordingProvider);

    switch (state.status) {
      case VoiceStatus.idle:
        // Check mic permission
        if (!await _recorder.hasPermission()) return;
        // Start recording
        await notifier.startRecording();
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '', // Web uses blob URLs
        );
        break;

      case VoiceStatus.recording:
        // Stop recording and get bytes
        await _recorder.stop();
        // On web, we need to fetch the blob
        // The record package handles this internally
        // For now, we'll create a placeholder — in production, the record
        // package returns a blob URL on web that needs to be fetched
        notifier.setAudioBytes(Uint8List(0)); // Placeholder for web blob
        await notifier.stopAndProcess();
        break;

      case VoiceStatus.error:
        notifier.reset();
        break;

      case VoiceStatus.done:
        notifier.reset();
        break;

      case VoiceStatus.processing:
        // Do nothing — wait for processing to complete
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceRecordingProvider);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: state.status == VoiceStatus.recording ? 72 : 60,
        height: state.status == VoiceStatus.recording ? 72 : 60,
        decoration: BoxDecoration(
          gradient: state.status == VoiceStatus.recording
              ? const LinearGradient(colors: [AppTheme.error, Color(0xFFFF8A8A)])
              : AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: state.status == VoiceStatus.recording
              ? [BoxShadow(color: AppTheme.error.withValues(alpha: 0.4), blurRadius: 20)]
              : AppTheme.glowShadow,
        ),
        child: Center(child: _buildIcon(state)),
      ),
    );
  }

  Widget _buildIcon(VoiceState state) {
    switch (state.status) {
      case VoiceStatus.idle:
        return const Icon(Icons.mic_rounded, size: 28, color: Colors.white);

      case VoiceStatus.recording:
        return const Icon(Icons.stop_rounded, size: 32, color: Colors.white)
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 800.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 800.ms,
            );

      case VoiceStatus.processing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        );

      case VoiceStatus.done:
        return const Icon(Icons.check_rounded, size: 28, color: Colors.white);

      case VoiceStatus.error:
        return const Icon(Icons.refresh_rounded, size: 28, color: Colors.white);
    }
  }
}
