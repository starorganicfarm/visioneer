import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:currency/wallet.dart';
import 'package:currency/main.dart';

late List<CameraDescription> cameras;

class YoloVideo extends StatefulWidget {
  final double balance;
  YoloVideo({Key? key, required this.balance}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late FlutterVision vision;
  late FlutterTts flutterTts;
  late List<Map<String, dynamic>> yoloResults; //<labels,confidence>
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  bool continueDetection = true;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    init();
    vision = myModel.vision;
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      setState(() {
        isLoaded = true;
        yoloResults = [];
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    startDetection();
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        continueDetection = false;
        return true;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          displayBoxAroundMostProminentObject(size),
        ],
      ),
    );
  }

  List<String> previousOutputs = [];
  List<String> currencyLabels = ['01', '02', '05','10', '20', '50', '75', '100', '500', '1000','5000'];
  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    if (!continueDetection || cameraImage == null) {
      return;
    }
    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.2,
      confThreshold: 0.2,
      classThreshold: 0.5,
    );
    // Filter only the currency objects
    List<Map<String, dynamic>> currencyResults = result.where((object) {
      String label = object['tag'];
      return currencyLabels.contains(label);
    }).toList();

    if (currencyResults.isNotEmpty) {
      setState(() {
        yoloResults = currencyResults;
      });

      String outputText = result[0]['tag'];
      print(outputText);

      // Add current output to previousOutputs list
      previousOutputs.add(outputText);

      // Check if previous 2 outputs are the same
      if (previousOutputs.length >= 4) {
        bool allSame = true;
        String firstOutput = previousOutputs.first;
        for (final output in previousOutputs) {
          if (output != firstOutput) {
            allSame = false;
            break;
          }
        }
        // If previous 2 outputs are the same, speak output once
        if (allSame) {
          await flutterTts.speak(outputText);
          print(outputText);
          continueDetection = false;
          previousOutputs.clear();

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Wallet(outputText: outputText)),
          );
        } else {
          // Remove oldest output from previousOutputs list
          previousOutputs.removeAt(0);
        }
      }
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  Widget noDetectionWidget() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Text(
          'No detection found',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
          ),
        ),
      ),
    );
  }

  Widget displayBoxAroundMostProminentObject(Size screen) {
    if (yoloResults.isEmpty) {
      // If no detections, display the "No detection found" widget
      return noDetectionWidget();
    }

    // Find the object with the highest confidence
    double highestConfidence = 0;
    Map<String, dynamic> mostProminentObject = yoloResults[0];
    for (final result in yoloResults) {
      double confidence = result['box'][4];
      if (confidence > highestConfidence) {
        highestConfidence = confidence;
        mostProminentObject = result;
      }
    }

    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return Positioned(
      left: mostProminentObject["box"][0] * factorX,
      top: mostProminentObject["box"][1] * factorY,
      width: (mostProminentObject["box"][2] - mostProminentObject["box"][0]) * factorX,
      height: (mostProminentObject["box"][3] - mostProminentObject["box"][1]) * factorY,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          border: Border.all(color: Colors.pink, width: 2.0),
        ),
        child: Text(
          "${mostProminentObject['tag']} ${(mostProminentObject['box'][4] * 100).toStringAsFixed(0)}%",
          style: TextStyle(
            background: Paint()..color = colorPick,
            color: Colors.white,
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }
}
