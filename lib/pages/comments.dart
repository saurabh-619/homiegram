import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homiegram/pages/activity_feed.dart';
import 'package:homiegram/pages/home.dart';
import 'package:homiegram/widgets/header.dart';
import 'package:homiegram/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId, postOwnerId, postMediaUrl;
  Comments({this.postId, this.postMediaUrl, this.postOwnerId});
  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postMediaUrl: this.postMediaUrl,
        postOwnerId: this.postOwnerId,
      );
}

class CommentsState extends State<Comments> {
  final String postId, postOwnerId, postMediaUrl;
  TextEditingController commentController = TextEditingController();

  CommentsState({this.postId, this.postMediaUrl, this.postOwnerId});

  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  // Adding comments
  void addComment() {
    commentsRef.document(postId).collection('comments').add({
      'username': currentUser.username,
      'comment': commentController.text,
      'timestamp': DateTime.now(),
      'avatarUrl': currentUser.photoUrl,
      'userId': currentUser.id,
    });

    bool isNotPostOwner = currentUser.id != postOwnerId;
    if (isNotPostOwner) {
      activityFeedsRef.document(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text,
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': postMediaUrl,
        'timestamp': timestamp,
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Comments'),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Write a comment...'),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text('Post'),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username, userId, avatarUrl, comment;
  final Timestamp timestamp;

  Comment({
    this.avatarUrl,
    this.username,
    this.comment,
    this.timestamp,
    this.userId,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      comment: doc['comment'],
      avatarUrl: doc['avatarUrl'],
      timestamp: doc['timestamp'],
      userId: doc['userId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: GestureDetector(
            onTap: () => showProfile(context, profileID: userId),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
            ),
          ),
          title: Text(comment),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider()
      ],
    );
  }
}
