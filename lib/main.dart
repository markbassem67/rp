import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'package:rp/history_screen.dart';
import 'package:rp/image_recognition_screen.dart';
import 'package:rp/live_feed_screen.dart';
import 'detection_record.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(camera: cameras.first),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;

  HomeScreen({required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<DetectionRecord> history = [];

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: LiveRecognitionScreen(camera: widget.camera),
          item: ItemConfig(
            icon: const Icon(CupertinoIcons.camera_fill),
            title: "Live Recognition",
            activeForegroundColor: const Color.fromRGBO(0, 91, 196, 1),
          ),
        ),
        PersistentTabConfig(
          screen: TakePictureScreen(camera: widget.camera),
          item: ItemConfig(
            icon: const Icon(CupertinoIcons.person_crop_rectangle_fill),
            title: "Image Upload",
            activeForegroundColor: const Color.fromRGBO(0, 91, 196, 1),
          ),
        ),
        PersistentTabConfig(
          screen: HistoryScreen(
            history: history,
            onClearHistory: () {
              setState(() {
                history.clear();
              });
            },
          ),
          item: ItemConfig(
            icon: const Icon(CupertinoIcons.clock_solid),
            title: "History",
            activeForegroundColor: const Color.fromRGBO(0, 91, 196, 1),
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style6BottomNavBar(
        navBarConfig: navBarConfig,
      ),
    );
  }
}
