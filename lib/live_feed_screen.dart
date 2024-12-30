import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:rp/camera_screen.dart';

class LiveRecognitionScreen extends StatefulWidget {
  final CameraDescription camera;

  const LiveRecognitionScreen({super.key, required this.camera});

  @override
  State<LiveRecognitionScreen> createState() => _LiveRecognitionScreenState();
}

class _LiveRecognitionScreenState extends State<LiveRecognitionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  String _recognizedName = "No faces detected";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false, // Use medium for balance between performance and quality
    );
    _initializeControllerFuture = _controller.initialize();
    _controller.setFocusMode(FocusMode.locked);
    _controller.setExposureMode(ExposureMode.locked);
    _startFrameProcessing();
  }

  /*@override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }*/

  void _startFrameProcessing() {
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        _processFrame();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _processFrame() async {
    if (_isProcessing || !_controller.value.isInitialized) return;

    try {
      _isProcessing = true;

      // Get the current frame
      final xFile = await _controller.takePicture();
      final Uint8List bytes = await File(xFile.path).readAsBytes();

      // Preprocess the image using the 'image' package
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        setState(() {
          _recognizedName = "Error decoding image";
        });
        return;
      }
      final img.Image resizedImage =
          img.copyResize(originalImage, width: 500, height: 500);
      final List<int> jpegBytes = img.encodeJpg(resizedImage);

      // Send the preprocessed frame to the server
      final uri = Uri.parse('http://192.168.1.12:5000/recognise');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', jpegBytes,
          filename: 'frame.jpg'));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 200 && decodedResponse['faces'].isNotEmpty) {
        setState(() {
          _recognizedName = decodedResponse['faces'][0]['name'];
        });
      } else {
        setState(() {
          _recognizedName = "No faces detected";
        });
      }
    } catch (e) {
      print("Error during frame processing: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                _recognizedName,
                style: const TextStyle(color: Colors.white, fontSize: 20,fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Live Recognition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Image Recognition',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (_currentIndex == 1) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TakePictureScreen(camera: widget.camera)));
            }
          });
        },
      ),
    );
  }
}
