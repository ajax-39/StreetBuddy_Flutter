import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/video_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double aspectRatio;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoProvider()..initializeVideoPlayer(videoUrl),
      child: _VideoPlayerContent(
        thumbnailUrl: thumbnailUrl,
        aspectRatio: aspectRatio,
      ),
    );
  }
}

class _VideoPlayerContent extends StatelessWidget {
  final String? thumbnailUrl;
  final double aspectRatio;

  const _VideoPlayerContent({
    this.thumbnailUrl,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoState, child) {
        if (!videoState.isInitialized) {
          return AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              color: Colors.black,
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            if (!videoState.isPlaying) {
              videoState.togglePlay(); // Start playing only when tapped
            } else {
              videoState.toggleMute();
            }
          },
          onLongPressStart: (_) => videoState.handleHoldStart(),
          onLongPressEnd: (_) => videoState.handleHoldEnd(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: videoState.controller!.value.aspectRatio,
                child: VideoPlayer(videoState.controller!),
              ),
              // Show play button when video is not playing
              if (!videoState.isPlaying)
                Container(
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
              if (videoState.showPlayIcon && videoState.isPlaying)
                Icon(
                  videoState.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                ),
              if (videoState.showMuteIcon)
                Icon(
                  videoState.isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                ),
              if (videoState.isHolding)
                Icon(
                  Icons.pause,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
