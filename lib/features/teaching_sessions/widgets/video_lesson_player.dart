import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoLessonPlayer extends StatefulWidget {
  final VideoPlayerController? videoController;
  final String courseName;
  final bool isPlaying;
  final double videoProgress;
  final Function toggleVideo;

  const VideoLessonPlayer({
    Key? key,
    required this.videoController,
    required this.courseName,
    required this.isPlaying,
    required this.videoProgress,
    required this.toggleVideo,
  }) : super(key: key);

  @override
  _VideoLessonPlayerState createState() => _VideoLessonPlayerState();
}

class _VideoLessonPlayerState extends State<VideoLessonPlayer> {
  bool _showControls = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Auto-play video when initialized
    if (widget.videoController != null &&
        widget.videoController!.value.isInitialized) {
      widget.toggleVideo(); // Trigger play
    }
    // Show controls initially, hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    // Auto-hide controls after 3 seconds if playing
    if (_showControls && widget.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && widget.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Reset orientation and system UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultHeight = screenWidth * (9 / 16); // 16:9 aspect ratio

    return Container(
      width: screenWidth,
      height: _isFullScreen
          ? MediaQuery.of(context).size.height
          : (widget.videoController != null &&
                  widget.videoController!.value.isInitialized
              ? screenWidth / widget.videoController!.value.aspectRatio
              : defaultHeight),
      color: Colors.black, // No decoration, just black background
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video display
          widget.videoController != null &&
                  widget.videoController!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: widget.videoController!.value.aspectRatio,
                  child: VideoPlayer(widget.videoController!),
                )
              : Container(
                  color: Colors.black87,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

          // Gesture detector for tap to show controls and toggle play/pause
          GestureDetector(
            onTap: () {
              _toggleControls();
              if (!_showControls) {
                widget.toggleVideo();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Custom controls (hidden in fullscreen unless tapped)
          if (!_isFullScreen || _showControls)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Stack(
                children: [
                  // Bottom controls (progress bar, play/pause, etc.)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          widget.videoController != null &&
                                  widget.videoController!.value.isInitialized
                              ? VideoProgressIndicator(
                                  widget.videoController!,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: const Color(0xFF5E5CE6),
                                    bufferedColor: Colors.grey.withOpacity(0.5),
                                    backgroundColor: Colors.grey.withOpacity(0.3),
                                  ),
                                  padding: EdgeInsets.zero,
                                )
                              : FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.videoProgress,
                                  child: Container(
                                    height: 4,
                                    color: const Color(0xFF5E5CE6),
                                  ),
                                ),

                          const SizedBox(height: 8),

                          // Control buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Time display
                              widget.videoController != null &&
                                      widget.videoController!.value.isInitialized
                                  ? Text(
                                      '${_formatDuration(widget.videoController!.value.position)} / ${_formatDuration(widget.videoController!.value.duration)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : const Text(
                                      '0:00 / 0:00',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),

                              // Control buttons
                              Row(
                                children: [
                                  // Rewind 10 seconds
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (widget.videoController != null &&
                                          widget.videoController!
                                              .value.isInitialized) {
                                        final currentPosition = widget
                                            .videoController!.value.position;
                                        final newPosition = currentPosition -
                                            const Duration(seconds: 10);
                                        widget.videoController!
                                            .seekTo(newPosition);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Play/Pause button
                                  IconButton(
                                    iconSize: 24,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => widget.toggleVideo(),
                                    icon: Icon(
                                      widget.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Forward 10 seconds
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (widget.videoController != null &&
                                          widget.videoController!
                                              .value.isInitialized) {
                                        final currentPosition = widget
                                            .videoController!.value.position;
                                        final newPosition = currentPosition +
                                            const Duration(seconds: 10);
                                        widget.videoController!
                                            .seekTo(newPosition);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Fullscreen toggle
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: _toggleFullScreen,
                                    icon: Icon(
                                      _isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top overlay (video title and quality, only in non-fullscreen)
                  if (!_isFullScreen)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Video title
                            Expanded(
                              child: Text(
                                widget.courseName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Video quality selector
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }
}