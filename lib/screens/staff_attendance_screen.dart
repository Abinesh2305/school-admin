import 'dart:async';
import 'camera_blink_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class StaffAttendanceScreen extends StatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  // ================= CONFIG =================
  final double officeLat = 11.498550;
  final double officeLng = 78.644714;
  final double allowedRadius = 100; // meters

  // ================= STATE =================
  bool _insideRadius = false;
  bool _loading = false;
  bool _showCamera = false;
  bool _isPunchedIn = false;

  double _distance = 0;
  Position? _stablePosition;

  CameraController? _cameraController;
  bool _cameraReady = false;

  StreamSubscription<Position>? _gpsSub;

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _disposeCamera();
    super.dispose();
  }

  // ================= INIT =================
  Future<void> _init() async {
    await _requestPermissions();
    _startStableGps();
  }

  // ================= PERMISSIONS =================
  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.camera.request();
  }

  // ================= GPS (VALIDATE FIRST) =================
  void _startStableGps() {
    _gpsSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
        ).listen((pos) {
          if (pos.accuracy > 50) return; // ignore bad fixes

          final dist = Geolocator.distanceBetween(
            officeLat,
            officeLng,
            pos.latitude,
            pos.longitude,
          );

          setState(() {
            _stablePosition = pos;
            _distance = dist;
            _insideRadius = dist <= allowedRadius;
          });
        });
  }

  // ================= PUNCH CLICK =================
  Future<void> _onPunchPressed() async {
  if (!_insideRadius) {
    _show("You are outside office radius");
    return;
  }

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraBlinkScreen(
        isPunchedIn: _isPunchedIn,
        lat: _stablePosition!.latitude,
        lng: _stablePosition!.longitude,
        distance: _distance,
      ),
    ),
  );

  if (result == true) {
    setState(() {
      _isPunchedIn = !_isPunchedIn;
    });

    _show("Attendance marked successfully");
  }
}


  // ================= CAMERA =================
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      _cameraReady = false;
    }
  }

  // ================= CAPTURE & MARK =================
  Future<void> _captureAndMark() async {
    if (_cameraController == null || !_cameraReady) return;

    setState(() => _loading = true);

    try {
      final photo = await _cameraController!.takePicture();

      final success = await _markAttendance(
        type: _isPunchedIn ? "punch_out" : "punch_in",
        photoPath: photo.path,
      );

      if (success) {
        setState(() {
          _isPunchedIn = !_isPunchedIn;
          _showCamera = false;
        });

        await _disposeCamera();

        _show("Attendance marked successfully");
      }
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  

  // ================= API =================
  Future<bool> _markAttendance({
    required String type,
    required String photoPath,
  }) async {
    final form = FormData.fromMap({
      "type": type,
      "lat": _stablePosition!.latitude,
      "lng": _stablePosition!.longitude,
      "distance": _distance.toStringAsFixed(0),
      "photo": await MultipartFile.fromFile(photoPath),
    });

    final res = await Dio().post(
      "https://api.example.com/attendance",
      data: form,
    );

    return res.statusCode == 200 && res.data["status"] == 1;
  }

  // ================= MAP =================
  Widget _mapCard() {
    if (_stablePosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 230,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _stablePosition!.latitude,
              _stablePosition!.longitude,
            ),
            zoom: 17,
          ),

          
          myLocationEnabled: true,
          myLocationButtonEnabled: true,

          circles: {
            Circle(
              circleId: const CircleId("office"),
              center: LatLng(officeLat, officeLng),
              radius: allowedRadius,
              fillColor: Colors.green.withOpacity(0.25),
              strokeColor: Colors.green,
              strokeWidth: 2,
            ),
          },

          markers: {
            Marker(
              markerId: const MarkerId("office"),
              position: LatLng(officeLat, officeLng),
            ),
          },
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Staff Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _mapCard(),
            const SizedBox(height: 12),
            _radiusStatus(),
            const SizedBox(height: 20),
            if (_showCamera) _cameraSection(),
            if (!_showCamera) _punchButton(),
          ],
        ),
      ),
    );
  }

  Widget _radiusStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _insideRadius ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _insideRadius ? Icons.check_circle : Icons.error,
            color: _insideRadius ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _insideRadius
                  ? "Inside radius (${_distance.toStringAsFixed(0)} m)"
                  : "Outside radius (${_distance.toStringAsFixed(0)} m)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _punchButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_insideRadius && !_loading) ? _onPunchPressed : null,
        child: Text(
          _isPunchedIn ? "Punch Out" : "Punch In",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _cameraSection() {
    if (!_cameraReady || _cameraController == null) {
      return const Text("Opening camera...");
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: CameraPreview(_cameraController!),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text("CAPTURE"),
            onPressed: _loading ? null : _captureAndMark,
          ),
        ),
      ],
    );
  }

  // ================= HELPER =================
  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
