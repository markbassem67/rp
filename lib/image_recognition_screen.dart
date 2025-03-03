import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:rp/custom_elevated_button.dart';
import 'package:rp/facerecognition_screen.dart';
import 'package:rp/live_feed_screen.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = false; // Loading state
  int _currentIndex = 1;

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
  }

  /*@override
  void dispose() {
    //_controller.dispose();
    super.dispose();
  }*/

  Future<File> normalizeImageOrientation(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final normalizedImage = img.bakeOrientation(decodedImage);
      final normalizedBytes = img.encodeJpg(normalizedImage);
      final normalizedFile = File(imagePath);
      await normalizedFile.writeAsBytes(normalizedBytes);
      return normalizedFile;
    }
    return imageFile;
  }

  Future<File> resizeImage(String imagePath, int width, int height) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final resizedImage =
          img.copyResize(decodedImage, width: width, height: height);
      final resizedBytes = img.encodeJpg(resizedImage);
      final resizedFile = File(imagePath);
      await resizedFile.writeAsBytes(resizedBytes);
      return resizedFile;
    }
    return imageFile;
  }

  Future<void> sendImageToServer(String imagePath) async {
    final uri = Uri.parse(
        'http://192.168.1.14:5000/recognise'); // Replace with your server IP
    final request = http.MultipartRequest('POST', uri);

    try {
      setState(() {
        _isLoading = true;
      });

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        if (decodedResponse['faces'] != null) {
          showDialog(
            context: context,
            builder: (context) {
              final names = (decodedResponse['faces'] as List)
                  .map((face) => face['name'])
                  .join(', ');

              return AlertDialog(
                title: const Text('Recognition Result'),
                content: Text(names.isNotEmpty ? names : 'No faces recognized'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error during sending image: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomElevatedButton(
                label: 'Choose from photos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FaceRecognitionPage()),
                  );
                },
                icon: const Icon(
                  CupertinoIcons.photo_fill_on_rectangle_fill,
                  size: 30,
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              CustomElevatedButton(
                label: 'Take image',
                icon: const Icon(
                  CupertinoIcons.camera_circle_fill,
                  size: 35,
                ),
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();

                    if (!context.mounted) return;

                    // Normalize and resize image before sending to server
                    final normalizedImageFile =
                        await normalizeImageOrientation(image.path);
                    final resizedImageFile =
                        await resizeImage(normalizedImageFile.path, 500, 500);

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Captured Image'),
                        content: Image.file(File(resizedImageFile.path)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              sendImageToServer(resizedImageFile
                                  .path); // Send image to server
                            },
                            child: const Text('Send to Server'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Retake'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    print("Error during image capture: $e");
                  }
                },
              ),
              const SizedBox(
                height: 20,
              )
            ],
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
            label: 'Image Recognition',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (_currentIndex == 0) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          LiveRecognitionScreen(camera: widget.camera)));
            }
          });
        },
      ),
    );
  }
}
