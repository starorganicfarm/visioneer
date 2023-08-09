import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:currency/splash_screen.dart';

class MyModel {
  late FlutterVision vision;
  Future<void> loadModel() async {
    vision = FlutterVision();
    await vision.loadYoloModel(
      labels: 'assets/labelcurr.txt',
      modelPath: 'assets/currency.tflite',
      modelVersion: "yolov5",
      numThreads: 3,
      useGpu: true,
    );
  }
}

MyModel myModel = MyModel();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp()); // Pass MyModel to MyApp
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
