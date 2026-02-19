import 'dart:async';
import 'package:camera/camera.dart';
import 'package:steermate/services/ml_service.dart';
import 'package:steermate/services/trip_logger_service.dart';

class CameraService {
  CameraController? _controller;
  final MLService _mlService = MLService();
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isProcessing = false;
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      // Use back camera
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // Balance quality and performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _mlService.initialize();

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Camera initialization failed: $e');
      return false;
    }
  }

  Future<void> startCapture(void Function(SignDetection) onDetection) async {
    if (!_isInitialized || _controller == null) return;
    if (_isStreaming) return;

    _isStreaming = true;
    await _controller!.startImageStream((CameraImage image) async {
      if (!_isStreaming) return;
      if (_isProcessing) return;

      // Throttle inference to ~2 FPS.
      final now = DateTime.now();
      if (now.difference(_lastInference).inMilliseconds < 450) return;

      _isProcessing = true;
      _lastInference = now;
      try {
        final detection = await _mlService.detectSign(image);
        if (detection != null) {
          onDetection(detection);
        }
      } catch (_) {
        // swallow per-frame errors
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> stopCapture() async {
    if (!_isStreaming) return;
    _isStreaming = false;
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  void dispose() {
    // Intentionally not awaiting in dispose
    _isStreaming = false;
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}