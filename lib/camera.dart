import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'info.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
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

  Future<List<Uint8List>?> _sendImageToServer(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        _showError('Failed to decode image');
        return null;
      }

      // Preserve image quality and format
      final jpg = img.encodeJpg(image, quality: 100);

      // Create multipart request
      final uri = Uri.parse('http://192.168.60.112:5100/segment');
      final request = http.MultipartRequest('POST', uri);

      // Add the image as a byte stream with correct headers
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          jpg,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send request and get response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> segmentedImageData =
              responseData['segmented_images'];

          // Process and validate each image
          List<Uint8List> processedImages = [];
          for (String base64String in segmentedImageData) {
            try {
              // Decode base64 and validate image data
              final imageBytes = base64Decode(base64String);
              final decodedImage = img.decodeImage(imageBytes);

              if (decodedImage != null) {
                // Re-encode with high quality to ensure consistency
                final processedJpg = img.encodeJpg(decodedImage, quality: 100);
                processedImages.add(Uint8List.fromList(processedJpg));
              } else {
                print('Failed to decode segmented image');
              }
            } catch (e) {
              print('Error processing segmented image: $e');
            }
          }

          if (processedImages.isEmpty) {
            _showError('No valid segmented images received');
            return null;
          }

          return processedImages;
        } catch (e) {
          _showError('Error parsing response: $e');
          return null;
        }
      } else {
        _showError(
            'Server error: ${response.statusCode}\nResponse: ${response.body}');
        return null;
      }
    } catch (e) {
      _showError('Network or processing error: $e');
      return null;
    }
  }

  Future<bool> _validateImageQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return false;

      // Check image dimensions
      if (image.width < 100 || image.height < 100) {
        print('Image resolution too low');
        return false;
      }

      // Check file size (minimum 50KB)
      if (bytes.length < 50 * 1024) {
        print('Image file size too small');
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating image: $e');
      return false;
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
                onTap: () async {
                  if (!_isCameraInitialized ||
                      _controller == null ||
                      !_controller!.value.isInitialized ||
                      _isProcessing) return;

                  setState(() {
                    _isProcessing = true;
                  });

                  try {
                    final XFile image = await _controller!.takePicture();
                    final File imageFile = File(image.path);

                    // Validate image quality
                    final bool isValidImage =
                        await _validateImageQuality(imageFile);
                    if (!isValidImage) {
                      _showError('Image quality too low. Please try again.');
                      return;
                    }

                    // Show loading indicator
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );
                    }

                    // Send image to segmentation server
                    final response = await _sendImageToServer(imageFile);

                    // Hide loading indicator
                    if (mounted) {
                      Navigator.of(context).pop();
                    }

                    if (response != null && response.isNotEmpty && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InfoPage(segmentedImages: response),
                        ),
                      );
                    } else {
                      _showError('Failed to process image. Please try again.');
                    }
                  } catch (e) {
                    _showError('Error capturing image: $e');
                  } finally {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                },
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
