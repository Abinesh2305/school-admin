import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class CropYourImageScreen extends StatefulWidget {
  final File imageFile;

  const CropYourImageScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<CropYourImageScreen> createState() => _CropYourImageScreenState();
}

class _CropYourImageScreenState extends State<CropYourImageScreen> {
  final CropController _controller = CropController();
  Uint8List? _imageData;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _imageData = widget.imageFile.readAsBytesSync();
  }

  Future<void> _onCrop() async {
    setState(() => _cropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    _handleCroppedImage(result);
  }

  Future<void> _handleCroppedImage(CropResult result) async {
    // CropResult is a sealed class with CropSuccess and CropFailure
    if (result is CropSuccess) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(path);
      await file.writeAsBytes(result.croppedImage);

      if (!mounted) return;
      Navigator.pop(context, file);
    } else if (result is CropFailure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crop failed: ${result.cause}')),
      );
    }
    setState(() => _cropping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Document'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _imageData == null
            ? const Center(child: CircularProgressIndicator())
            : Crop(
                controller: _controller,
                image: _imageData!,
                onCropped: _onCropped,
                withCircleUi: false,
                interactive: true,
                baseColor: Colors.black,
                maskColor: Colors.black.withOpacity(0.6),
                cornerDotBuilder: (size, edgeAlignment) =>
                    const DotControl(color: Colors.teal),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cropping ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _cropping ? null : _onCrop,
                  child: _cropping
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crop'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
