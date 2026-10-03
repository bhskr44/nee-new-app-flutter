import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Lazily initializes a network video only once the user taps play, so the
/// feed doesn't try to buffer every video at once.
class CommunityVideoPlayer extends StatefulWidget {
  final String url;
  const CommunityVideoPlayer({super.key, required this.url});

  @override
  State<CommunityVideoPlayer> createState() => _CommunityVideoPlayerState();
}

class _CommunityVideoPlayerState extends State<CommunityVideoPlayer> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _loading = false;

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    final videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await videoCtrl.initialize();
    if (!mounted) return;
    setState(() {
      _videoCtrl = videoCtrl;
      _chewieCtrl = ChewieController(
        videoPlayerController: videoCtrl,
        autoPlay: true,
        looping: false,
        aspectRatio: videoCtrl.value.aspectRatio,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieCtrl != null) {
      return AspectRatio(aspectRatio: _videoCtrl!.value.aspectRatio, child: Chewie(controller: _chewieCtrl!));
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : IconButton(
                  onPressed: _start,
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                ),
        ),
      ),
    );
  }
}
