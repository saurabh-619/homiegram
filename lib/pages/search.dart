import 'package:flutter/material.dart';
import 'package:homiegram/pages/home.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homiegram/widgets/progress.dart';
import 'package:homiegram/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'activity_feed.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  void handleSearch(String searchedText) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isGreaterThanOrEqualTo: searchedText)
        .getDocuments();

    setState(() {
      searchResultsFuture = users;
    });
  }

  void clearSearch() {
    searchController.clear();
    setState(() {
      searchResultsFuture = null;
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Color(0xff202020),
      title: TextFormField(
        style: TextStyle(color: Colors.white),
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search For user...',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            color: Colors.deepPurpleAccent,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.deepPurpleAccent,
            ),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300 : 200,
            ),
            Text(
              'Find Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60,
              ),
            )
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          searchResults.add(UserResult(user));
        });

        return ListView(
          children: searchResults,
        );
      },
    );
  }

  // getters for keep states alive while user is changinh widgets
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    // getters for keep states alive while user is changinh widgets
    super.build(context);

    return Scaffold(
      // backgroundColor: Theme.of(context).primaryColor.withOpacity(.8),
      backgroundColor: Colors.black,
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Theme.of(context).primaryColor.withOpacity(.7),
      color: Colors.black,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileID: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Divider(
          //   height: 2,
          //   color: Colors.white,
          // ),
        ],
      ),
    );
  }
}
