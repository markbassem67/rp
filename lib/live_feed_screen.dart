import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:rp/detection_record.dart';
import 'package:rp/history_screen.dart';
import 'package:rp/image_recognition_screen.dart';

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
  List<String> _recognizedNames = ["No faces detected"];
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _recognizedPeople = {};
   final List<DetectionRecord> history=[];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _controller.setFocusMode(FocusMode.locked);
    _controller.setExposureMode(ExposureMode.locked);
    _startFrameProcessing();
  }

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

      final xFile = await _controller.takePicture();
      final Uint8List bytes = await File(xFile.path).readAsBytes();

      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        setState(() {
          _recognizedNames = ["Error decoding image"];
        });
        return;
      }

      final img.Image resizedImage =
          img.copyResize(originalImage, width: 500, height: 500);
      final List<int> jpegBytes = img.encodeJpg(resizedImage);

      final uri = Uri.parse('http://192.168.1.81:5000/recognise');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', jpegBytes,
          filename: 'frame.jpg'));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      //print("Server Response: $decodedResponse"); // Debugging

      if (response.statusCode == 200 && decodedResponse['faces'].isNotEmpty) {
        List<dynamic> faces = decodedResponse['faces'];

        setState(() {
          _recognizedNames = faces.map((f) => f['name']).join(', ') as List<String>;
        });

        for (var face in faces) {
          String detectedPerson = face['name'];
          if (!_recognizedPeople.contains(detectedPerson)) {
            _recognizedPeople.add(detectedPerson);
            _audioPlayer.play(AssetSource('Ding-Sound-Effect.mp3'));
          }
          history.add(DetectionRecord(
            name: detectedPerson,
            timestamp: DateTime.now(),
          ));
        }
      }
      else {
        setState(() {
          _recognizedNames = ["No faces detected"];
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
      appBar: AppBar(
        title: const Text(
          'Live Feed',
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
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
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Column(
                children: _recognizedNames
                    .map((name) => Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        unselectedFontSize: 18,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.camera_fill),
            label: 'Live Recognition',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_rectangle_fill),
            label: 'Image Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock_solid),
            label: 'Session History',
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
            } else if (_currentIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    history: history,
                    onClearHistory: () {
                      setState(() {
                        history.clear();
                        _recognizedPeople
                            .clear(); // Optional: reset recognition state
                      });
                    },
                  ),
                ),
              );
            }
          });
        },
        enableFeedback: false,
      ),
    );
  }
}

