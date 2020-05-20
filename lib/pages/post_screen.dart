import 'package:flutter/material.dart';
import 'package:homiegram/pages/home.dart';
import 'package:homiegram/widgets/header.dart';
import 'package:homiegram/widgets/post.dart';
import 'package:homiegram/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;
  PostScreen({this.postId, this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: circularProgress(),
          );
        }

        Post post = Post.fromDocument(snapshot.data);

        return Center(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: header(
              context,
              titleText: post.caption,
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
