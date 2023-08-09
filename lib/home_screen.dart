import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:currency/yolovideo.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  double balance;

  HomeScreen({Key? key, required this.balance}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // Speak the initial instruction when the screen opens
    Future.delayed(Duration(milliseconds: 500), () {
      flutterTts.speak('Double tap to open camera');
    });
  }

  void _resetBalance() async {
    // Your reset balance logic here
    setState(() {
      widget.balance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        exit(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Color(0xff2196f3),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
              Future.delayed(const Duration(seconds: 3), () {
                flutterTts.speak('Your Current Balance is ${widget.balance} rupees');
              });
              Future.delayed(const Duration(seconds: 7), () {
                flutterTts.speak('Swipe left to close wallet');
              });
            },
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Balance: ${widget.balance}',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Reset Balance'),
                onTap: () {
                  _resetBalance();
                },
              ),
            ],
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: () {
            // Code to navigate to the camera screen (YoloVideo) on double-tap
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => YoloVideo(balance: widget.balance),
              ),
            );
            flutterTts.speak('Camera Open');
          },
          child: Center(
            child: Text(
              'Double-tap to open camera',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
