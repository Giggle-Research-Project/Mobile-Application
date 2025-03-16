import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:giggle/core/services/database.service.dart';
import 'package:giggle/core/widgets/next_button.dart';
import 'package:giggle/features/teaching_sessions/analyticsTracker.dart';
import 'package:giggle/features/teaching_sessions/widgets/concentration_monitor.dart';
import 'package:giggle/features/teaching_sessions/widgets/focus_indicator.dart';
import 'package:giggle/features/teaching_sessions/widgets/lesson_info.dart';
import 'package:giggle/features/teaching_sessions/widgets/video_lesson_player.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:http/http.dart' as http;

class TeachingSessionScreen extends StatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;
  final bool isCompleted;

  const TeachingSessionScreen({
    super.key,
    this.difficultyLevels,
    required this.courseName,
    required this.dyscalculiaType,
    required this.questions,
    required this.userId,
    required this.isCompleted,
  });

  @override
  State<TeachingSessionScreen> createState() => _TeachingSessionScreenState();
}

class _TeachingSessionScreenState extends State<TeachingSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Constants
  static const _monitoringInterval = Duration(seconds: 2);
  static const _navigationDelay = Duration(milliseconds: 50);

  // Animation
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // State flags
  bool _isPlaying = false;
  bool _isCameraInitialized = false;
  bool _isNavigating = false;
  bool _isCleaningUp = false;

  // Camera and analysis
  CameraController? _cameraController;
  double _concentrationScore = 0.0;
  String _concentrationStatus = 'Monitoring...';
  String _emotionStatus = 'Neutral';
  Color _statusColor = Colors.grey;

  // WebSockets
  WebSocketChannel? _concentrationChannel;
  WebSocketChannel? _emotionChannel;

  // Timers
  Timer? _concentrationTimer;
  Timer? _emotionTimer;
  Timer? _videoTimer;

  // Video
  double _videoProgress = 0.0;
  VideoPlayerController? _videoController;

  // Analytics
  late LearningAnalyticsTracker _analyticsTracker;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeAnalytics();
    _initializeVideo();
    WidgetsBinding.instance.addObserver(this);

    // Initialize resources after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeResources();
      }
    });
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  void _initializeAnalytics() {
    _analyticsTracker = LearningAnalyticsTracker(
      userId: widget.userId,
      courseName: widget.courseName,
      dyscalculiaType: widget.dyscalculiaType,
    );
    _analyticsTracker.startSession();
  }

  // VIDEO HANDLING

  String _getVideoPath() {
    return 'assets/videos/${widget.dyscalculiaType.replaceAll(" ", "_")}_${widget.courseName.replaceAll(" ", "_")}.mp4';
  }

  Future<void> _initializeVideo() async {
    final videoAsset = _getVideoPath();
    _logInfo('Attempting to load video from: $videoAsset');

    _videoController = VideoPlayerController.asset(videoAsset);
    try {
      await _videoController!.initialize();
      _logInfo('Video initialized successfully');
      if (mounted) setState(() {});
    } catch (e) {
      _logError('Error initializing video: $e');
    }
  }

  void _toggleVideo() {
    if (_videoController == null) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  // CAMERA HANDLING

  Future<void> _initializeResources() async {
    await _initializeCamera();
    _setupWebSockets();
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startMonitoring();
      }
    } catch (e) {
      _logError('Error initializing camera: $e');
      _isCameraInitialized = false;
    }
  }

  // ML SERVER COMMUNICATION

  Future<void> _sendCameraFrameForPrediction(String imagePath) async {
    try {
      _logInfo('Sending camera frame to ML server: $imagePath');
      _logInfo('ML Server IP: 51.20.86.30');

      // Get concentration prediction
      final concentrationData = await _getPrediction(
        endpoint: 'predict-concentration',
        imagePath: imagePath,
      );
      _updateConcentrationStatus(concentrationData);

      // Get emotion prediction
      final emotionData = await _getPrediction(
        endpoint: 'detect-emotion',
        imagePath: imagePath,
      );
      _updateEmotionStatus(emotionData);
    } catch (e) {
      _logError('Error sending camera frame for prediction: $e');
      // Fallback to default states
      _updateConcentrationStatus({'concentration_score': 0.5});
      _updateEmotionStatus({'emotion': 'Neutral', 'confidence': 0.0});
    }
  }

  Future<dynamic> _getPrediction({
    required String endpoint,
    required String imagePath,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.endPoint}/$endpoint/');

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    _logInfo('$endpoint Raw Response: $responseBody');

    return _parseJsonSafely(responseBody);
  }

  dynamic _parseJsonSafely(String jsonString) {
    jsonString = jsonString.trim();

    if (jsonString.isEmpty) {
      throw FormatException('Empty response');
    }

    try {
      return jsonDecode(jsonString);
    } on FormatException catch (e) {
      _logError('JSON Parsing Error: $e');
      _logError('Problematic JSON string: "$jsonString"');
      throw e;
    }
  }

  // DATA UPDATES AND MONITORING

  void _updateConcentrationStatus(dynamic data) {
    try {
      double score = _extractConcentrationScore(data);
      score = score.clamp(0.0, 1.0);

      _logInfo('Raw Concentration Data: $data');
      _logInfo('Calculated Concentration Score: $score');

      if (!widget.isCompleted) {
        _analyticsTracker.updateConcentration(score);
      }

      setState(() {
        _concentrationScore = score;
        _updateStatusBasedOnScore(score);
      });
    } catch (e) {
      _logError('Concentration status update error: $e');
      setState(() {
        _concentrationScore = 0.5;
        _concentrationStatus = 'Monitoring...';
        _statusColor = Colors.grey;
      });
    }
  }

  double _extractConcentrationScore(dynamic data) {
    if (data is Map) {
      return (data['concentration_score'] ??
          data['score'] ??
          data['confidence'] ??
          0.5) as double;
    } else if (data is String) {
      return double.tryParse(data) ?? 0.5;
    }
    return 0.5;
  }

  void _updateStatusBasedOnScore(double score) {
    if (score >= 0.8) {
      _concentrationStatus = 'Highly Focused';
      _statusColor = const Color(0xFF30D158);
    } else if (score >= 0.5) {
      _concentrationStatus = 'Moderately Focused';
      _statusColor = const Color(0xFFFFA500);
    } else {
      _concentrationStatus = 'Distracted';
      _statusColor = const Color(0xFFFF3B30);
    }

    _logInfo('Concentration Status: $_concentrationStatus');
    _logInfo('Status Color: $_statusColor');
  }

  void _updateEmotionStatus(dynamic data) {
    try {
      final emotionData = _extractEmotionData(data);
      final emotion = emotionData.emotion;
      final confidence = emotionData.confidence;

      if (!widget.isCompleted) {
        _analyticsTracker.updateEmotion(emotion, confidence);
      }

      setState(() {
        _emotionStatus = '$emotion (${(confidence * 100).toStringAsFixed(1)}%)';
        _logInfo('Updated emotion: $_emotionStatus');
      });
    } catch (e) {
      _logError('Error processing emotion data: $e');
      setState(() {
        _emotionStatus = 'Neutral (0.0%)';
      });
    }
  }

  ({String emotion, double confidence}) _extractEmotionData(dynamic data) {
    String emotion = 'Neutral';
    double confidence = 0.0;

    if (data is Map) {
      emotion =
          (data['emotion'] ?? data['predicted_emotion'] ?? 'Neutral') as String;
      confidence = (data['confidence'] ??
          data['prob'] ??
          data['probability'] ??
          0.0) as double;
    }

    return (emotion: emotion, confidence: confidence.clamp(0.0, 1.0));
  }

  // WEBSOCKETS AND MONITORING

  void _setupWebSockets() {
    _logInfo('Setting up WebSockets with ML IP: 51.20.86.30');

    try {
      _setupConcentrationWebSocket();
      _setupEmotionWebSocket();
    } catch (e) {
      _logError('Error setting up WebSockets: $e');
      // If WebSockets fail, use HTTP fallback
      _startConcentrationMonitoring();
    }
  }

  void _setupConcentrationWebSocket() {
    final concentrationUri = Uri.parse(ApiEndpoints.concentrationWebSocket);
    _concentrationChannel = WebSocketChannel.connect(concentrationUri);
    _concentrationChannel!.stream.listen(
      (data) {
        _logInfo('Concentration WebSocket Received: $data');
        _updateConcentrationStatus(data is String ? jsonDecode(data) : data);
      },
      onError: (error) {
        _logError('Concentration WebSocket Error: $error');
        _reconnectWebSocket('concentration');
      },
      onDone: () {
        _logInfo('Concentration WebSocket Connection Closed');
        _reconnectWebSocket('concentration');
      },
    );
  }

  void _setupEmotionWebSocket() {
    final emotionUri = Uri.parse(ApiEndpoints.detectEmotion);
    _emotionChannel = WebSocketChannel.connect(emotionUri);
    _emotionChannel!.stream.listen(
      (data) {
        _logInfo('Emotion WebSocket Received: $data');
        _updateEmotionStatus(data is String ? jsonDecode(data) : data);
      },
      onError: (error) {
        _logError('Emotion WebSocket Error: $error');
        _reconnectWebSocket('emotion');
      },
      onDone: () {
        _logInfo('Emotion WebSocket Connection Closed');
        _reconnectWebSocket('emotion');
      },
    );
  }

  void _startMonitoring() {
    _startConcentrationMonitoring();
  }

  void _startConcentrationMonitoring() {
    _concentrationTimer?.cancel();
    _concentrationTimer = Timer.periodic(
      _monitoringInterval,
      (timer) async {
        if (_cameraController != null &&
            _cameraController!.value.isInitialized &&
            _isPlaying &&
            mounted) {
          try {
            final image = await _cameraController!.takePicture();
            await _sendCameraFrameForPrediction(image.path);
          } catch (e) {
            _logError('Error in concentration monitoring: $e');
          }
        }
      },
    );
  }

  void _reconnectWebSocket(String socketType) {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      if (socketType == 'concentration') {
        _setupConcentrationWebSocket();
      } else if (socketType == 'emotion') {
        _setupEmotionWebSocket();
      }
    });
  }

  // RESOURCE MANAGEMENT

  void _forceCleanupSync() {
    try {
      // Cancel all timers immediately
      _concentrationTimer?.cancel();
      _emotionTimer?.cancel();
      _videoTimer?.cancel();
      _concentrationTimer = null;
      _emotionTimer = null;
      _videoTimer = null;

      // Try to close WebSockets without awaiting
      _concentrationChannel?.sink.close();
      _emotionChannel?.sink.close();
      _concentrationChannel = null;
      _emotionChannel = null;

      _analyticsTracker.finalizeSession();

      // Try to stop video
      _videoController?.pause();

      // Try to stop camera
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _cameraController!.dispose();
      }
      _cameraController = null;

      _isCameraInitialized = false;
      _isPlaying = false;
    } catch (e) {
      _logError('Error in force cleanup: $e');
    }
  }

  Future<void> _cleanupResources() async {
    if (!mounted || _isCleaningUp) return;
    _isCleaningUp = true;

    // Use a structured approach to cleanup
    await _cleanupVideo();
    _cleanupTimers();
    await _cleanupWebSockets();
    await _cleanupCamera();
    await _notifyMLServer();

    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isPlaying = false;
        _videoProgress = 0.0;
        _concentrationScore = 0.0;
        _concentrationStatus = 'Monitoring...';
        _emotionStatus = 'Neutral';
        _statusColor = Colors.grey;
        _isCleaningUp = false;
      });
    }
  }

  Future<void> _cleanupVideo() async {
    try {
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
      }
    } catch (e) {
      _logError('Error disposing video controller: $e');
    }
  }

  void _cleanupTimers() {
    try {
      _concentrationTimer?.cancel();
      _emotionTimer?.cancel();
      _videoTimer?.cancel();

      _analyticsTracker.finalizeSession();

      _concentrationTimer = null;
      _emotionTimer = null;
      _videoTimer = null;
    } catch (e) {
      _logError('Error cancelling timers: $e');
    }
  }

  Future<void> _cleanupWebSockets() async {
    try {
      if (_concentrationChannel != null) {
        await _concentrationChannel!.sink.close();
        _concentrationChannel = null;
      }

      if (_emotionChannel != null) {
        await _emotionChannel!.sink.close();
        _emotionChannel = null;
      }
    } catch (e) {
      _logError('Error closing WebSocket channels: $e');
    }
  }

  Future<void> _cleanupCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
        _cameraController = null;
      }
    } catch (e) {
      _logError('Error disposing camera controller: $e');
    }
  }

  Future<void> _notifyMLServer() async {
    try {
      final uri = Uri.parse(ApiEndpoints.stopStream);
      await http.get(uri).timeout(const Duration(seconds: 2));
    } catch (e) {
      _logError('Error notifying ML server: $e');
    }
  }

  // NAVIGATION

  void _handleBackPress() {
    _onWillPop();
  }

  Future<bool> _onWillPop() async {
    if (_isNavigating) return false;
    setState(() {
      _isNavigating = true;
    });

    // Synchronous cleanup
    _forceCleanupSync();

    // Short delay then navigate
    await Future.delayed(_navigationDelay);
    if (mounted && context.mounted) {
      Navigator.of(context).pop();
    }
    return false;
  }

  void _navigateToInteractiveSession() async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // Only update the database if isCompleted is false
    if (!widget.isCompleted) {
      await DatabaseService().updateVideoLessonProgress(
        widget.userId,
        widget.courseName,
        widget.dyscalculiaType,
      );
    } else {
      _logInfo('Skipping database update as session is already completed');
    }

    _forceCleanupSync();

    Future.delayed(_navigationDelay, () {
      if (mounted && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          _logError('Navigation error: $e');
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        }
      }
    });
  }

  // LIFECYCLE MANAGEMENT

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed) {
      _initializeResources();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _forceCleanupSync();
    _controller.dispose();
    super.dispose();
  }

  // LOGGING

  void _logInfo(String message) {
    print(message);
  }

  void _logError(String message) {
    print('❌ $message');
  }

  // UI COMPONENTS

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        body: Stack(
          children: [
            const BackgroundPattern(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          VideoLessonPlayer(
                            videoController: _videoController,
                            courseName: widget.courseName,
                            isPlaying: _isPlaying,
                            videoProgress: _videoProgress,
                            toggleVideo: _toggleVideo,
                          ),
                          const SizedBox(height: 20),
                          ConcentrationMonitor(
                            concentrationStatus: _concentrationStatus,
                            concentrationScore: _concentrationScore,
                            statusColor: _statusColor,
                            isCameraInitialized: _isCameraInitialized,
                            cameraController: _cameraController,
                            emotionStatus: _emotionStatus,
                            onEmotionDetected: (emotion) {
                              setState(() {
                                _emotionStatus = emotion;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          LessonInfo(
                            dyscalculiaType: widget.dyscalculiaType,
                            courseName: widget.courseName,
                            concentrationScore: _concentrationScore,
                          ),
                          const SizedBox(height: 20),
                          NextButton(
                            onTap: _navigateToInteractiveSession,
                            text: 'Complete Session',
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _handleBackPress,
                            child: Container(
                              height: 45,
                              width: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Teaching Session',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Learning ${widget.dyscalculiaType}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      FocusIndicator(
                        statusColor: _statusColor,
                        concentrationScore: _concentrationScore,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
