import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:giggle/core/services/predict_emotion_ravdess.service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceEmotionDetector extends StatefulWidget {
  final Function(String emotion) onEmotionDetected;

  const VoiceEmotionDetector({
    Key? key,
    required this.onEmotionDetected,
  }) : super(key: key);

  @override
  State<VoiceEmotionDetector> createState() => _VoiceEmotionDetectorState();
}

class _VoiceEmotionDetectorState extends State<VoiceEmotionDetector> {
  AudioRecorder? _audioRecorder;
  Timer? _recordingTimer;
  String _currentEmotion = 'neutral';
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      _audioRecorder = AudioRecorder();

      final hasPermission = await _audioRecorder?.hasPermission() ?? false;
      if (!hasPermission) {
        print('No permission for audio recording');
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      if (mounted) {
        _startRecordingCycle();
      }
    } catch (e) {
      print('Error initializing recorder: $e');
      _isInitialized = false;
    }
  }

  Future<void> _startNewRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      // Clean up previous recording if exists
      if (_currentRecordingPath != null) {
        final previousFile = File(_currentRecordingPath!);
        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.wav';

      final recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      );

      if (_currentRecordingPath != null) {
        await _audioRecorder?.start(recordConfig, path: _currentRecordingPath!);
      }

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
    }
  }

  Future<void> _stopAndAnalyzeRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder?.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        await PredictVoiceEmotionService().predictEmotion(
          File(path),
          widget.onEmotionDetected,
          mounted,
          setState,
          _currentEmotion,
        );
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _startRecordingCycle() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isRecording) {
        await _stopAndAnalyzeRecording();
      } else {
        await _startNewRecording();
      }
    });

    // Start first recording immediately
    _startNewRecording();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder?.dispose();
    _cleanupRecordings();
    super.dispose();
  }

  Future<void> _cleanupRecordings() async {
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error cleaning up recordings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isInitialized ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_off,
                color: _isRecording ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 12),
              const Text(
                'Voice Emotion Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getEmotionColor(_currentEmotion).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getEmotionIcon(_currentEmotion),
                  size: 20,
                  color: _getEmotionColor(_currentEmotion),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentEmotion.toUpperCase(),
                  style: TextStyle(
                    color: _getEmotionColor(_currentEmotion),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'fearful':
        return Colors.purple;
      case 'disgust':
        return Colors.green;
      case 'surprised':
        return Colors.orange;
      case 'calm':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.mood_bad;
      case 'fearful':
        return Icons.warning;
      case 'disgust':
        return Icons.sick;
      case 'surprised':
        return Icons.sentiment_very_satisfied;
      case 'calm':
        return Icons.self_improvement;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
