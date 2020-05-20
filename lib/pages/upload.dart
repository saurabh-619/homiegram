import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homiegram/models/user.dart';
import 'package:homiegram/pages/home.dart';
import 'package:homiegram/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isUploading = false;
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  String postId = Uuid().v4();
  // Image picker for capture photo
  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallary() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  //Diosplay Image Picker
  pickImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create post'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: handleTakePhoto,
              child: Text(
                'Photo with camera',
              ),
            ),
            SimpleDialogOption(
              onPressed: handleChooseFromGallary,
              child: Text(
                'Image from gallary',
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }

  // Splash Screen
  Container buildSplashScreen() {
    return Container(
      // color: Theme.of(context).accentColor.withOpacity(0.75),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          SizedBox(
            height: 20,
          ),
          RaisedButton(
            color: Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Upload Image',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => pickImage(context),
          )
        ],
      ),
    );
  }

  // ClearImage
  clearImage() {
    setState(() {
      file = null;
    });
  }

  // Compress image
  compressImage() async {
    // Set temp Directory
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    // Decode image
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());

    // Sote img at path
    final compressedImg = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImg;
    });
  }

  // Create post in firestore with caption, imgUrl, loaction in posts collection
  createPostInFirestore({String mediaUrl, String caption, String location}) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'location': location,
      'timestamp': timestamp,
      'likes': {}
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  // Upload image
  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;

    //  Get uploaded file url
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  // Post image
  handleSubmit() async {
    // removes keyboard
    FocusScope.of(context).unfocus();
    setState(() {
      isUploading = true;
    });
    await compressImage();

    // Send compressed img to upload in firestore bucket
    String mediaUrl = await uploadImage(file);

    // Create post in firestore with caption, imgUrl, loaction in posts collection
    createPostInFirestore(
      mediaUrl: mediaUrl,
      caption: captionController.text,
      location: locationController.text,
    );
  }

  // Get user location
  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark placemark = placemarks[0];
    // String completeAddress =
    //     '${placemark.subThoroughfare} ${placemark.thoroughfare} ${placemark.subLocality} ${placemark.locality} ${placemark.subAdministrativeArea} ${placemark.administrativeArea} ${placemark.postalCode} ${placemark.country} ';

    String formattedAddress =
        '${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.country}';
    locationController.text = formattedAddress;
  }

  // Upload form
  Scaffold buildUploadForm() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xff202020),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: clearImage,
        ),
        title: Text(
          'Caption Post',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post ',
              style: TextStyle(
                color: isUploading ? Colors.grey : Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.currentUser.photoUrl,
              ),
            ),
            title: Container(
              width: 250,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              size: 35,
              color: Colors.deepPurpleAccent,
            ),
            title: Container(
              width: 250,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: locationController,
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.white),
                  hintText: 'Where was this photo taken ?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            height: 100,
            width: 200,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                'Use Current location',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.deepOrange,
            ),
          )
        ],
      ),
    );
  }

  // getters for keep states alive while user is changinh widgets

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // getters for keep states alive while user is changinh widgets
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
