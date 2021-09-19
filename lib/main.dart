import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:kraken_test/conf_room.dart';
import 'package:kraken_test/kraken/kraken.dart';

late KrakenClient client;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kraken Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Kraken Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  TextEditingController _ipcontroller = TextEditingController();
  TextEditingController _useridcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _controller.text = 'user1';
    _ipcontroller.text = '192.168.0.107';
    _useridcontroller.text = '1';
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Enter a name to recognise you.',
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Enter user id (number)',
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _useridcontroller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),            
            Text(
              'Enter Server IP.',
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _ipcontroller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _handleEnter();
              },
              child: Text("Enter Room"),
            ),
          ],
        ),
      ),
    );
  }

  _handleEnter() async {
    String ipAddress = _ipcontroller.text.trim();
    if (ipAddress.isEmpty) ipAddress = "192.168.0.107";
    showLoading();
    try {
      // final result = await post(
      //   Uri.parse('http://$ipAddress:7000'),
      // );
      // log("RESULT : ${result.body}");
      client = KrakenClient(ipAddress);
      final userId = int.parse(_useridcontroller.text.trim());
      client.join('test', _controller.text.trim(), userId);
    } catch (e) {
      dismissLoading();
      log("Exception : $e");
      return;
    }
    dismissLoading();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConferenceRoom(
          username: _controller.text.trim(),
        ),
      ),
    );
  }

  showLoading() {
    showDialog(
      context: context,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
  }

  dismissLoading() {
    Navigator.of(context).pop();
  }
}
