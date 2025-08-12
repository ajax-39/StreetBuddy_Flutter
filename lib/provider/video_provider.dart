import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProvider extends ChangeNotifier {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showPlayIcon = false;
  bool _showMuteIcon = false;
  bool _isHolding = false;
  String? _currentVideoUrl;
  bool _isDisposed = false;

  VideoPlayerController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  bool get showPlayIcon => _showPlayIcon;
  bool get showMuteIcon => _showMuteIcon;
  bool get isHolding => _isHolding;

  Future<void> initializeVideoPlayer(String videoUrl) async {
    if (_currentVideoUrl == videoUrl && _controller != null) {
      return;
    }

    try {
      // Clean up old controller
      await _cleanupController();

      if (_isDisposed) return;

      _currentVideoUrl = videoUrl;
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();

      if (_isDisposed) {
        await _cleanupController();
        return;
      }

      _controller!.setLooping(true);
      _isInitialized = true;
      _isPlaying = false; // Don't auto-play
      // await _controller!.play(); // Remove auto-play
      _isMuted = true;
      await _controller!.setVolume(0);

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _isInitialized = false;
      await _cleanupController();
      notifyListeners();
    }
  }

  Future<void> _cleanupController() async {
    try {
      await _controller?.pause();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _currentVideoUrl = null;
    } catch (e) {
      debugPrint('Error cleaning up controller: $e');
    }
  }

  Future<void> togglePlay() async {
    if (_controller == null || !_isInitialized) return;

    try {
      _isPlaying = !_isPlaying;
      _showPlayIcon = true;

      if (_isPlaying) {
        await _controller!.play();
      } else {
        await _controller!.pause();
      }

      if (!_isDisposed) {
        notifyListeners();

        // Hide play/pause icon after delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            _showPlayIcon = false;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling play state: $e');
    }
  }

  Future<void> toggleMute() async {
    if (_controller == null || !_isInitialized) return;

    try {
      _isMuted = !_isMuted; // Toggle mute state
      _showMuteIcon = true; // Show mute/unmute icon
      notifyListeners();

      if (_isMuted) {
        await _controller!.setVolume(0); // Mute the media
      } else {
        await _controller!.setVolume(1); // Unmute the media
      }

      if (!_isDisposed) {
        // Hide mute/unmute icon after delay
        _hideMuteIconAfterDelay();
      }
    } catch (e) {
      debugPrint('Error toggling mute state: $e');
    }
  }

  void _hideMuteIconAfterDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && _showMuteIcon) {
        _showMuteIcon = false; // Hide mute/unmute icon
        notifyListeners();
      }
    });
  }

  Future<void> handleHoldStart() async {
    if (_isPlaying && !_isHolding && _controller != null) {
      try {
        _isHolding = true;
        await _controller!.pause();
        if (!_isDisposed) notifyListeners();
      } catch (e) {
        debugPrint('Error handling hold start: $e');
      }
    }
  }

  Future<void> handleHoldEnd() async {
    if (_isPlaying && _isHolding && _controller != null) {
      try {
        _isHolding = false;
        await _controller!.play();
        if (!_isDisposed) notifyListeners();
      } catch (e) {
        debugPrint('Error handling hold end: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupController();
    super.dispose();
  }
}
