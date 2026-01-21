import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:dio/dio.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as mlc;

class CameraBlinkScreen extends StatefulWidget {
  final bool isPunchedIn;
  final double lat;
  final double lng;
  final double distance;

  const CameraBlinkScreen({
    super.key,
    required this.isPunchedIn,
    required this.lat,
    required this.lng,
    required this.distance,
  });

  @override
  State<CameraBlinkScreen> createState() => _CameraBlinkScreenState();
}

class _CameraBlinkScreenState extends State<CameraBlinkScreen> {
  CameraController? _controller;
  late FaceDetector _faceDetector;

  bool _blinkDetected = false;
  bool _eyesWereOpen = false;
  bool _eyesClosedOnce = false;
  bool _capturing = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  // ================= CAMERA INIT =================
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processFrame);

    if (mounted) setState(() {});
  }

  // ================= BLINK PROCESS =================
  Future<void> _processFrame(CameraImage image) async {
    if (_processing || _blinkDetected) return;
    _processing = true;

    try {
      final inputImage = _cameraImageToInputImage(image);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return;

      final face = faces.first;
      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;
      if (left == null || right == null) return;

      final eyesOpen = left > 0.6 && right > 0.6;
      final eyesClosed = left < 0.3 && right < 0.3;

      if (eyesOpen && !_eyesWereOpen) _eyesWereOpen = true;
      if (_eyesWereOpen && eyesClosed) _eyesClosedOnce = true;

      if (_eyesClosedOnce && eyesOpen && !_capturing) {
        _capturing = true;
        _blinkDetected = true;

        await _controller?.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 400));

        await _captureAndSend();
      }
    } finally {
      _processing = false;
    }
  }

  // ================= CAPTURE & API =================
  Future<void> _captureAndSend() async {
    final file = await _controller!.takePicture();

    final form = FormData.fromMap({
      "type": widget.isPunchedIn ? "punch_out" : "punch_in",
      "lat": widget.lat,
      "lng": widget.lng,
      "distance": widget.distance.toStringAsFixed(0),
      "photo": await MultipartFile.fromFile(file.path),
    });

    final res = await Dio().post(
      "https://api.example.com/attendance",
      data: form,
    );

    Navigator.pop(context, res.statusCode == 200 && res.data["status"] == 1);
  }

  // ================= IMAGE CONVERSION =================
  mlc.InputImage _cameraImageToInputImage(CameraImage image) {
  final WriteBuffer buffer = WriteBuffer();
  for (final Plane plane in image.planes) {
    buffer.putUint8List(plane.bytes);
  }
  final Uint8List bytes = buffer.done().buffer.asUint8List();

  final Size imageSize = Size(
    image.width.toDouble(),
    image.height.toDouble(),
  );

  final mlc.InputImageRotation rotation =
      _rotationFromSensor(_controller!.description.sensorOrientation);

  final mlc.InputImageFormat format =
      mlc.InputImageFormatValue.fromRawValue(image.format.raw) ??
          mlc.InputImageFormat.yuv420;

  return mlc.InputImage.fromBytes(
    bytes: bytes,
    metadata: mlc.InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow, 
    ),
  );
}



  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blink Verification")),
      body: Column(
        children: [
          Expanded(
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _blinkDetected
                  ? "Blink verified. Capturing..."
                  : "Please blink your eyes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _blinkDetected ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
