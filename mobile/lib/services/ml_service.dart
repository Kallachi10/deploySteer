import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:steermate/services/trip_logger_service.dart';
import 'package:image/image.dart' as img;

class MLService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  
  // Model configuration
  static const String modelPath = 'assets/models/traffic_sign_model.tflite';
  static const int inputSize = 224;
  static const List<String> labels = [
    'speed_limit_30',
    'speed_limit_50',
    'speed_limit_60',
    'speed_limit_80',
    'speed_limit_100',
    'speed_limit_120',
    'stop',
    'yield',
    'no_entry',
  ];
  
  Future<bool> initialize() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Get input/output shapes
      var inputTensors = _interpreter!.getInputTensors();
      var outputTensors = _interpreter!.getOutputTensors();
      
      print('Model loaded. Input: $inputTensors, Output: $outputTensors');
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing ML model: $e');
      print('Note: Place a trained TFLite model at $modelPath');
      _isInitialized = false;
      return false;
    }
  }
  
  Future<SignDetection?> detectSign(CameraImage cameraImage) async {
    if (!_isInitialized || _interpreter == null) {
      return null;
    }
    
    try {
      // Convert camera image to format expected by model
      final input = _preprocessImage(cameraImage);
      
      // Run inference
      final output = List.generate(1, (_) => List.filled(labels.length, 0.0));
      _interpreter!.run(input, output);
      
      // Find best prediction
      double maxConfidence = 0.0;
      int bestIndex = -1;
      final outputList = output[0] as List;
      for (int i = 0; i < labels.length; i++) {
        final confidence = (outputList[i] as num).toDouble();
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          bestIndex = i;
        }
      }
      
      // Only return if confidence is high enough
      if (maxConfidence > 0.5 && bestIndex >= 0) {
        return SignDetection(
          timestamp: DateTime.now(),
          className: labels[bestIndex],
          confidence: maxConfidence,
          bbox: {}, // Simplified - in production, use object detection model
        );
      }
      
      return null;
    } catch (e) {
      print('Error during inference: $e');
      return null;
    }
  }
  
  List<List<List<List<double>>>> _preprocessImage(CameraImage cameraImage) {
    // Convert YUV420 camera frame to RGB image.
    final rgbImage = _convertYUV420ToImage(cameraImage);
    if (rgbImage == null) {
      // Fallback: neutral gray input
      return List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (_) => List.generate(
            inputSize,
            (_) => List.filled(3, 0.5),
          ),
        ),
      );
    }

    // Resize to model input size.
    final resized = img.copyResize(
      rgbImage,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Normalize to [0, 1] float input.
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            final r = p.r / 255.0;
            final g = p.g / 255.0;
            final b = p.b / 255.0;
            return <double>[r, g, b];
          },
        ),
      ),
    );

    return input;
  }

  img.Image? _convertYUV420ToImage(CameraImage image) {
    if (image.format.group != ImageFormatGroup.yuv420) {
      return null;
    }

    final width = image.width;
    final height = image.height;

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final yBytes = planeY.bytes;
    final uBytes = planeU.bytes;
    final vBytes = planeV.bytes;

    final yRowStride = planeY.bytesPerRow;
    final uvRowStride = planeU.bytesPerRow;
    final uvPixelStride = planeU.bytesPerPixel ?? 1;

    final out = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final yRowOffset = yRowStride * y;
      final uvRowOffset = uvRowStride * (y >> 1);

      for (int x = 0; x < width; x++) {
        final yIndex = yRowOffset + x;
        final uvIndex = uvRowOffset + (x >> 1) * uvPixelStride;

        final yp = yBytes[yIndex];
        final up = uBytes[uvIndex];
        final vp = vBytes[uvIndex];

        final yf = yp.toDouble();
        final uf = (up - 128).toDouble();
        final vf = (vp - 128).toDouble();

        int r = (yf + 1.402 * vf).round();
        int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
        int b = (yf + 1.772 * uf).round();

        if (r < 0) r = 0;
        if (r > 255) r = 255;
        if (g < 0) g = 0;
        if (g > 255) g = 255;
        if (b < 0) b = 0;
        if (b > 255) b = 255;

        out.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return out;
  }
  
  double? extractSpeedLimit(String className) {
    if (className.startsWith('speed_limit_')) {
      final speedStr = className.replaceAll('speed_limit_', '');
      return double.tryParse(speedStr);
    }
    return null;
  }
  
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
