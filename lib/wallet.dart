import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currency/home_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Wallet extends StatefulWidget {
  final String outputText;
  const Wallet({Key? key, required this.outputText}) : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  double balance = 0;
  late FlutterTts flutterTts;
  bool hasSpoken = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _loadBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Perform the TTS call and ModalRoute check here
    if (!hasSpoken) {
      flutterTts.speak('Balance is ${widget.outputText} rupees');
      Future.delayed(const Duration(seconds: 3), () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          flutterTts.speak('There are two buttons you want to add or delete');
        }
      });
      hasSpoken = true;
    }
  }

  Future<void> _loadBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      balance = prefs.getDouble('balance') ?? 0;
    });
  }

  void _saveBalance(double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('balance', amount);
  }

  void _addValue(double amount) {
    setState(() {
      balance += amount;
      _saveBalance(balance);
    });
  }

  void _removeValue(double amount) {
    setState(() {
      balance -= amount;
      _saveBalance(balance);
    });
  }

  void _stopSpeaking() async {
    await flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(balance: balance)),
        );
        _stopSpeaking();
        return true;
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Text(
                  'Balance: Rs ${double.parse(widget.outputText)}',
                  style: TextStyle(fontSize: 30),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xff2196f3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (TextButton(
                      child: Text('ADD BALANCE'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        _addValue(double.parse(widget.outputText));
                        _stopSpeaking();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen(balance: balance)));
                      },
                    )),
                  ),
                  SizedBox(width: 20),
                  Container(
                    height: 60,
                    width: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xff2196f3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (TextButton(
                      child: Text('DELETE BALANCE'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        _removeValue(double.parse(widget.outputText));
                        _stopSpeaking();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen(balance: balance)));
                      },
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
