import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:video_player/video_player.dart';

class FileVideoPlayer extends StatefulWidget {
  final File videoFile;

  const FileVideoPlayer({super.key, required this.videoFile});

  @override
  _FileVideoPlayerState createState() => _FileVideoPlayerState();
}

class _FileVideoPlayerState extends State<FileVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  Duration _videoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoDuration = _controller.value.duration;
          // Store duration in seconds in the provider
          context.read<UploadProvider>().setDuration(_videoDuration.inSeconds);
        });
        // Remove auto-play - let user tap to play
        // _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: VideoPlayer(_controller),
                    ),
                    // Show play button overlay when video is paused
                    if (!_controller.value.isPlaying)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.play();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
