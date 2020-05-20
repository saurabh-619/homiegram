import 'dart:async';

import 'package:flutter/material.dart';
import 'package:homiegram/pages/home.dart';
import 'package:homiegram/widgets/progress.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 7),
      () => {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()))
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff00081F),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'HomieGram',
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Signatra', fontSize: 80),
              ),
              Image(
                image: AssetImage('assets/images/pre3.gif'),
                width: double.infinity,
              ),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.greenAccent, fontSize: 30),
              ),
            ],
          ),
        ));
  }
}
