import 'package:flutter/material.dart';

AppBar header(BuildContext context,
    {isAppTitle = false, String titleText, bool removeBackButton = true}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton, //removes backbutton
    title: Text(
      isAppTitle ? 'HomieGram' : titleText,
      style: TextStyle(
        fontFamily: isAppTitle ? 'Signatra' : '',
        fontSize: isAppTitle ? 40 : 24,
        color: Colors.white,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    // backgroundColor: Theme.of(context).accentColor,
    backgroundColor: Color(0xff202020),
  );
}
