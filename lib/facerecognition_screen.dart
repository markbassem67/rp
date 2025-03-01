import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rp/custom_elevated_button.dart';

class FaceRecognitionPage extends StatefulWidget {
  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  File? _selectedImage;
  List<Map<String, dynamic>> faces = [];
  double imageWidth = 0.0;
  double imageHeight = 0.0;
  bool isLoading = false; // Loading state

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        faces = [];
        isLoading = true; // Start loading
      });

      await _getImageDimensions(_selectedImage!);
      await sendImageToServer(_selectedImage!);
    }
  }

  Future<void> _getImageDimensions(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    setState(() {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    });
  }

  Future<void> sendImageToServer(File imageFile) async {
    final uri = Uri.parse('http://192.168.1.14:5000/recognise'); // Replace with your server IP
    final request = http.MultipartRequest('POST', uri);

    try {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          faces = List<Map<String, dynamic>>.from(decodedResponse['faces']);
        });
      } else {
        setState(() {
          faces = []; // Clear faces on error
          showErrorDialog('Error: ${response.reasonPhrase}');
        });
      }
    } catch (e) {
      showErrorDialog('Failed to send image to server: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: _selectedImage == null
          ? const Center(
        child: Text(
          'No image selected',
          style: TextStyle(fontSize: 25),
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          // Calculate aspect ratio and scale the image properly
          final displayWidth = constraints.maxWidth;
          final displayHeight = constraints.maxHeight;
          final aspectRatio = imageWidth > 0 && imageHeight > 0 ? imageWidth / imageHeight : 1;

          return Center(
            child: SizedBox(
              width: displayWidth,
              height: displayWidth / aspectRatio,
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: displayWidth,
                    height: displayWidth / aspectRatio,
                    fit: BoxFit.contain,
                  ),
                  ...faces.map((face) {
                    final coordinates = face['coordinates'];
                    final name = face['name'];

                    // Scale coordinates based on displayed image size
                    final scaledLeft =
                        coordinates['left'] * (displayWidth / imageWidth);
                    final scaledTop =
                        coordinates['top'] * ((displayWidth / aspectRatio) / imageHeight);
                    final scaledRight =
                        coordinates['right'] * (displayWidth / imageWidth);
                    final scaledBottom =
                        coordinates['bottom'] * ((displayWidth / aspectRatio) / imageHeight);

                    return Positioned(
                      left: scaledLeft,
                      top: scaledTop,
                      width: scaledRight - scaledLeft,
                      height: scaledBottom - scaledTop,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: name == 'Unknown Face' ? Colors.red : Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: name == 'Unknown Face' ? Colors.red : Colors.green,
                            child: Text(
                              name,
                              style:
                              const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
      isLoading // Show loading indicator when processing
          ? const CircularProgressIndicator()
          : CustomElevatedButton(
        onPressed: pickImage,
        label: 'Select Image',
        icon: const Icon(Icons.image),
      ),
    );
  }
}













/*
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rp/custom_elevated_button.dart';

class FaceRecognitionPage extends StatefulWidget {
  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  File? _selectedImage;
  List<Map<String, dynamic>> faces = [];
  double imageWidth = 0.0;
  double imageHeight = 0.0;

  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        faces = [];
      });

      await _getImageDimensions(File(pickedFile.path));
      await sendImageToServer(_selectedImage!);
    }
  }

  Future<void> _getImageDimensions(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    setState(() {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    });
  }

  Future<void> sendImageToServer(File imageFile) async {
    final uri = Uri.parse(
        'http://192.168.1.126:5000/recognise'); // Replace with your server IP
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final decodedResponse = jsonDecode(responseData);

    if (response.statusCode == 200) {
      setState(() {
        faces = List<Map<String, dynamic>>.from(decodedResponse['faces']);
      });
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: _selectedImage == null
          ? const Center(
          child: Text(
            'No image selected',
            style: TextStyle(fontSize: 25),
          ))
          : LayoutBuilder(
        builder: (context, constraints) {
          // Calculate aspect ratio and scale the image properly
          final displayWidth = constraints.maxWidth;
          final displayHeight = constraints.maxHeight;
          final aspectRatio = imageWidth / imageHeight;

          return Center(
            child: SizedBox(
              width: displayWidth,
              height: displayWidth / aspectRatio,
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: displayWidth,
                    height: displayWidth / aspectRatio,
                    fit: BoxFit.contain,
                  ),
                  ...faces.map((face) {
                    final coordinates = face['coordinates'];
                    final name = face['name'];

                    // Scale coordinates based on displayed image size
                    final scaledLeft =
                        coordinates['left'] * (displayWidth / imageWidth);
                    final scaledTop = coordinates['top'] *
                        ((displayWidth / aspectRatio) / imageHeight);
                    final scaledRight = coordinates['right'] *
                        (displayWidth / imageWidth);
                    final scaledBottom = coordinates['bottom'] *
                        ((displayWidth / aspectRatio) / imageHeight);

                    return Positioned(
                      left: scaledLeft,
                      top: scaledTop,
                      width: scaledRight - scaledLeft,
                      height: scaledBottom - scaledTop,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: name == 'Unknown Face'
                                ? Colors.red
                                : Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: name == 'Unknown Face'
                                ? Colors.red
                                : Colors.green,
                            child: Text(
                              name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomElevatedButton(
            onPressed: pickImage,
            label: 'Select image',
            icon: const Icon(Icons.image),
          ),
        ],
      ),
    );
  }
}*/
