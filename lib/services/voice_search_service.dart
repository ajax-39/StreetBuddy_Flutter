import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class for handling voice search functionality
class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false; 

  // Getters
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    try {
      // Check microphone permission
      final micPermission = await Permission.microphone.status;

      if (micPermission.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          debugPrint('🎤 Microphone permission denied');
          return false;
        }
      }

      if (micPermission.isPermanentlyDenied) {
        debugPrint('🎤 Microphone permission permanently denied');
        return false;
      }

      // Initialize speech to text
      _speechEnabled = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: true,
      );

      if (_speechEnabled) {
        debugPrint('✅ Speech recognition initialized successfully');
      } else {
        debugPrint('❌ Speech recognition failed to initialize');
      }

      return _speechEnabled;
    } catch (e) {
      debugPrint('❌ Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String localeId = 'en_US',
  }) async {
    if (!_speechEnabled) {
      debugPrint('❌ Speech not enabled - initializing...');
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return;
    }

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          debugPrint('🎤 Voice input: ${result.recognizedWords}');

          if (result.finalResult) {
            _isListening = false;
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      debugPrint('🎤 Started listening for voice input');
    } catch (e) {
      _isListening = false;
      debugPrint('❌ Error starting voice recognition: $e');
      onError('Failed to start voice recognition: $e');
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      debugPrint('🎤 Stopped listening');
    }
  }

  /// Cancel current listening session
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      debugPrint('🎤 Cancelled listening');
    }
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_speechEnabled) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Check if device has speech recognition capability
  Future<bool> hasSpeechRecognition() async {
    return await _speechToText.hasPermission;
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _isListening = false;
    debugPrint('🎤 Speech error: $error');
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    debugPrint('🎤 Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _isListening = false;
    _lastWords = '';
  }
}
