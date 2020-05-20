import 'package:flutter/material.dart';
import 'package:homiegram/pages/Splash.dart';
import 'package:homiegram/pages/home.dart';

void main() async {
  // tell firestore so that enable to use timestamps in stream
  // Firestore.instance.settings();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomieGram',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}
