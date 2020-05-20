import 'dart:async';

import 'package:flutter/material.dart';
import 'package:homiegram/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String username;
  final _key = GlobalKey<FormState>();

  submit() {
    FocusScope.of(context).unfocus();

    if (_key.currentState.validate()) {
      _key.currentState.save(); //calls onSaved function
      SnackBar snackbar = SnackBar(
        content: Text('Welcome $username'),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xff000000),
      appBar: header(context,
          titleText: 'Set up your profile', removeBackButton: false),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Center(
                    child: Text(
                      'Create a username',
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _key,
                    autovalidate: true,
                    child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val.isEmpty || val.trim().length < 4) {
                          return 'Username too short';
                        } else if (val.trim().length > 12) {
                          return 'Username too long';
                        } else {
                          return null;
                        }
                      },
                      onSaved: (val) => username = val,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                        labelStyle:
                            TextStyle(fontSize: 15, color: Colors.white),
                        hintText: 'Username must be at least 3 characters',
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
