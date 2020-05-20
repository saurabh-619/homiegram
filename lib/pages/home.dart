import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:homiegram/models/user.dart';
import 'package:homiegram/pages/activity_feed.dart';
import 'package:homiegram/pages/profile.dart';
import 'package:homiegram/pages/search.dart';
import 'package:homiegram/pages/timeline.dart';
import 'package:homiegram/pages/upload.dart';
import 'create_account.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersRef = Firestore.instance.collection('users');
final CollectionReference postsRef = Firestore.instance.collection('posts');
final CollectionReference activityFeedsRef =
    Firestore.instance.collection('feed');
final CollectionReference commentsRef =
    Firestore.instance.collection('comments');
final CollectionReference followersRef =
    Firestore.instance.collection('followers');
final CollectionReference followingRef =
    Firestore.instance.collection('following');
final CollectionReference timelineRef =
    Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();

final timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: pageIndex);
    // Detects whether we are signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error in signing in $err');
    });
    // Reauthenticate when app is opened again (for session)
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      print('User has returned');
      handleSignIn(account);
    }).catchError((err) => print(err));
  }

  void handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;

    // have to ask permissions for IOS only
    if (Platform.isIOS) getIOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print('Firebase messaging token: $token\n');

      usersRef.document(user.id).updateData({
        'androidNotificationToken': token,
      });
    });

    _firebaseMessaging.configure(
      // when app is openend after ling time
      // onLaunch: (Map<String,dynamic> message) async {},
      // when app is running in the bg
      // onResume: (Map<String, dynamic> message) async {},

      // send push notifications
      onMessage: (Map<String, dynamic> message) async {
        print('on message: \n$message\n');
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == user.id) {
          print('notifications shown');
          SnackBar snackbar = SnackBar(
            content: Text(
              body,
              overflow: TextOverflow.ellipsis,
            ),
          );

          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print('Notifications not setup');
      },
    );
  }

  getIOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));

    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print('Settings register $settings');
    });
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    // check if user already exists with ID
    // If user doesnt exist ,take to create account name page
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // Got username from create account, use it to make new account with username
      usersRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });

      // make user their own follower to seed their own post in timeline
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
      print(doc);
    }
    currentUser = User.fromDocument(doc);
    print(currentUser);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void login() {
    googleSignIn.signIn();
  }

  void signOut() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  void onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.bounceInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          Search(),
          Upload(currentUser: currentUser),
          ActivityFeed(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: Color(0xff202020),
        currentIndex: pageIndex,
        onTap: (value) {
          onTap(value);
        },
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.whatshot,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              // Theme.of(context).accentColor,
              // Theme.of(context).primaryColor,
              Color(0xff000000),
              Color(0xff202020),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'HomieGram',
              style: TextStyle(
                fontFamily: 'Signatra',
                color: Colors.white,
                fontSize: 90,
              ),
            ),
            GestureDetector(
              onTap: () {
                login();
              },
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
