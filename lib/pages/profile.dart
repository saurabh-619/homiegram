import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:homiegram/models/user.dart';
import 'package:homiegram/pages/edit_profile.dart';
import 'package:homiegram/widgets/header.dart';
import 'package:homiegram/widgets/post.dart';
import 'package:homiegram/widgets/post_tile.dart';
import 'package:homiegram/widgets/progress.dart';
import 'package:homiegram/pages/home.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String loggedInUserId = currentUser?.id;
  int postsCount = 0;
  String postOrientation = 'grid';
  bool isLoading = false;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  @override
  void initState() {
    super.initState();
    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(loggedInUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  // Get followers
  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  // Get following
  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postsCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  // Profile Data builder
  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w400),
          ),
        )
      ],
    );
  }

  // Edit the profile
  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: loggedInUserId)));
  }

  // Build button(Edit/follow)
  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
        onPressed: function,
        child: Container(
          height: 27,
          width: 250,
          child: Text(
            text,
            style: TextStyle(
                color: isFollowing ? Colors.white : Colors.white,
                fontWeight: FontWeight.bold),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isFollowing ? Colors.black : Colors.deepPurpleAccent,
              border: Border.all(
                  color: isFollowing ? Colors.grey : Colors.deepPurpleAccent),
              borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      followerCount--;
    });

    // make update in followers of user to which loggedInUser gonna unfollow in firestore
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(loggedInUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // make update in follwing collection of loggedInUser  and add id of user to whom loggedInUser is unfollowing in firestore
    followingRef
        .document(loggedInUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // add activity feed notification to follwed user
    activityFeedsRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(loggedInUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': loggedInUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': DateTime.now()
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
      followerCount++;
    });

    // make update in followers of user to which loggedInUser gonna follow in firestore
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(loggedInUserId)
        .setData({});

    // make update in follwing collection of loggedInUser  and add id of user to whom loggedInUser is following in firestore
    followingRef
        .document(loggedInUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    // add activity feed notification to follwed user
    activityFeedsRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(loggedInUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': loggedInUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': DateTime.now()
    });
  }

  // follow/edit profile button
  buildProfileButton() {
    // check if it is logged in users profile
    bool isProfileOwner = widget.profileId == loggedInUserId;
    if (isProfileOwner) {
      return buildButton(text: 'Edit Profile', function: editProfile);
    } else if (isFollowing) {
      return buildButton(text: 'Unfollow', function: handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(text: 'Follow', function: handleFollowUser);
    }
  }

  buidProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(
                      user.photoUrl,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn('posts', postsCount),
                            buildCountColumn('followers', followerCount - 1),
                            buildCountColumn('following', followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[buildProfileButton()],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                      color: Colors.white),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  user.bio,
                  style: TextStyle(
                      fontWeight: FontWeight.w400, color: Colors.white),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      // return circularProgress();
      return Text('');
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 220,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'No Posts',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach(
        (post) {
          gridTiles.add(
            GridTile(
              child: PostTile(
                post: post,
              ),
            ),
          );
        },
      );

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  togglePostOrientation(String orientation) {
    setState(() {
      this.postOrientation = orientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () {
            togglePostOrientation('grid');
          },
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () {
            togglePostOrientation('list');
          },
          icon: Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, isAppTitle: false, titleText: 'Profile'),
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          onRefresh: () async {
            await getProfilePost();
            await getFollowers();
            await getFollowing();
            await checkIfFollowing();
            return;
          },
          child: ListView(
            children: <Widget>[
              buidProfileHeader(),
              Divider(),
              buildTogglePostOrientation(),
              Divider(
                height: 0.0,
              ),
              buildProfilePosts(),
            ],
          ),
        ));
  }
}
