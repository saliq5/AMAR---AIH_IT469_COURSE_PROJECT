import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class AddImagePage extends StatefulWidget {
  const AddImagePage({Key? key}) : super(key: key);

  @override
  _AddImagePageState createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 8.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _cameras = await availableCameras();
        _controller = CameraController(_cameras!.first, ResolutionPreset.high);
        await _controller!.initialize();

        _minZoomLevel = await _controller!.getMinZoomLevel();
        _maxZoomLevel = await _controller!.getMaxZoomLevel();

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        _showError('Camera permission denied');
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  void _showError(String message) {
    print(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _onZoomChanged(double value) {
    if (_controller != null) {
      double newZoomLevel = value.clamp(_minZoomLevel, _maxZoomLevel);
      setState(() {
        _currentZoomLevel = newZoomLevel;
      });
      _controller!.setZoomLevel(_currentZoomLevel);
    }
  }

  Future<void> _captureAndReturnImage() async {
    if (!_isCameraInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await File(image.path).readAsBytes();

      // Returning the captured image as Uint8List to the previous screen
      Navigator.pop(context, imageBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture your medicine'),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTapDown: (details) {},
                    child: FractionallySizedBox(
                      widthFactor: 0.9,
                      heightFactor: 0.9,
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 120,
                  child: Column(
                    children: [
                      Text(
                        'Zoom',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Slider(
                        value: _currentZoomLevel,
                        min: _minZoomLevel,
                        max: _maxZoomLevel,
                        onChanged: _onZoomChanged,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _isCameraInitialized && !_isProcessing
          ? Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _captureAndReturnImage,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
