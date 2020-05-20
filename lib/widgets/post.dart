import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homiegram/models/user.dart';
import 'package:homiegram/pages/comments.dart';
import 'package:homiegram/pages/home.dart';
import 'package:homiegram/pages/activity_feed.dart';
import 'package:homiegram/widgets/custom_image.dart';
import 'package:homiegram/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId, ownerId, username, location, caption, mediaUrl;
  final dynamic likes;
  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      caption: doc['caption'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // check if likes
    if (likes == null) return 0;

    int count = 0;
    likes.values.forEach((like) {
      if (like == true) {
        count++;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        caption: this.caption,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likesCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> with AutomaticKeepAliveClientMixin<Post> {
  final String loggedInUserId = currentUser?.id;
  final String postId, ownerId, username, location, caption, mediaUrl;
  int likesCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  _PostState({
    this.postId,
    this.ownerId,
    this.location,
    this.username,
    this.caption,
    this.mediaUrl,
    this.likes,
    this.likesCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = loggedInUserId == ownerId;

        return ListTile(
          leading: GestureDetector(
            onTap: () => showProfile(context, profileID: ownerId),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
          ),
          title: GestureDetector(
            onTap: () {
              showProfile(context, profileID: ownerId);
            },
            child: Text(
              username,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          subtitle: Text(
            location,
            style: TextStyle(color: Colors.white),
          ),
          trailing: isPostOwner
              ? IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => handleDeletePost(context),
                )
              : Text(''),
        );
      },
    );
  }

  // handle delete post
  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Remove this Post ?'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text(
                  'Cancel',
                ),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  // delete a post i.e ownerId == loggedInUser
  deletePost() async {
    // delete post itself
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete uploaded image
    storageRef.child('post_$postId.jpg').delete();
    // delete all activity feed
    QuerySnapshot activityFeedSnapshot = await activityFeedsRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();

    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete all comments on the same post
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();

    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  // Handling likes
  handleLikePost() {
    bool _isLiked = likes[loggedInUserId] == true ? true : false;

    if (_isLiked) {
      //Dislike Update post in firestore
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$loggedInUserId': false});

      removeLikeFromActivityFeed();
      // Dislike
      setState(() {
        likesCount--;
        isLiked = false;
        likes[loggedInUserId] = false;
      });
    } else if (!_isLiked) {
      //Like Update post in firestore
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$loggedInUserId': true});

      addLikeToActivityFeed();
      // Like
      setState(() {
        likesCount++;
        isLiked = true;
        likes[loggedInUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 600), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUser.id != ownerId;
    if (isNotPostOwner) {
      activityFeedsRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  addLikeToActivityFeed() {
    // add notification to activity if liked by other than owner
    bool isNotPostOwner = currentUser.id != ownerId;
    if (isNotPostOwner) {
      activityFeedsRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId) //so thatonly new notification will be stored
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    }
  }

  GestureDetector buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator<double>(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.easeOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 120,
                      color: Colors.white60,
                    ),
                  ),
                )
              : Text(''),
        ],
      ),
    );
  }

  Column buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.deepPurpleAccent,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$likesCount likes',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$username ',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                caption,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        )
      ],
    );
  }

  // getters for keep states alive while user is changinh widgets
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // getters for keep states alive while user is changinh widgets
    super.build(context);
    isLiked = (likes[loggedInUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(
  context, {
  String postId,
  String ownerId,
  String mediaUrl,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Comments(
        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl,
      ),
    ),
  );
}
