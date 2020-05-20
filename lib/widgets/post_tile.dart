import 'package:flutter/material.dart';
import 'package:homiegram/pages/post_screen.dart';
import 'package:homiegram/widgets/custom_image.dart';
import 'package:homiegram/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile({this.post});

  // Show a single post on clicking post thumnail
  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
