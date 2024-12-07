import 'package:flutter/material.dart';
import 'package:giggle/features/function%2003/interactive_session.dart';
import 'package:video_player/video_player.dart';
import 'package:giggle/features/function%2002/interactive_session.dart';

class VideoLessonScreen extends StatefulWidget {
  final String videoUrl;

  const VideoLessonScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoLessonScreenState createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    // Initialize the video controller
    _videoController = VideoPlayerController.asset(widget.videoUrl);

    // Initialize the controller and store the Future for later use
    _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
      // Ensure the first frame is shown and the video starts paused
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose of the video controller when the widget is disposed
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player
            Center(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // If the VideoPlayerController has finished initialization
                    return AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    );
                  } else {
                    // If the VideoPlayerController is still initializing
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),

            // Video Controls Overlay
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause Button
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        // If the video is playing, pause it.
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          // If the video is paused, play it.
                          _videoController!.play();
                        }
                      });
                    },
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Start Interactive Session Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProceduralInteractiveSession(),
                        ),
                      );
                    },
                    child: const Text(
                      'Start Interactive Session',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
