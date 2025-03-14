import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video display
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.videoController != null &&
                    widget.videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: widget.videoController!.value.aspectRatio,
                    child: VideoPlayer(widget.videoController!),
                  )
                : Container(
                    color: const Color(0xFF1D1D1F).withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),

          // Gesture detector for tapping to play/pause
          GestureDetector(
            onTap: () => widget.toggleVideo(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Custom controls that appear on hover or tap
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
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
                              decoration: BoxDecoration(
                                color: const Color(0xFF5E5CE6),
                                borderRadius: BorderRadius.circular(2),
                              ),
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
                                    widget
                                        .videoController!.value.isInitialized) {
                                  final currentPosition =
                                      widget.videoController!.value.position;
                                  final newPosition = currentPosition -
                                      const Duration(seconds: 10);
                                  widget.videoController!.seekTo(newPosition);
                                }
                              },
                              icon: const Icon(
                                Icons.replay_10,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 12),

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
                                    widget
                                        .videoController!.value.isInitialized) {
                                  final currentPosition =
                                      widget.videoController!.value.position;
                                  final newPosition = currentPosition +
                                      const Duration(seconds: 10);
                                  widget.videoController!.seekTo(newPosition);
                                }
                              },
                              icon: const Icon(
                                Icons.forward_10,
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
          ),

          // Video title and info overlay at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
                        borderRadius: BorderRadius.circular(4),
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
