const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// When a user (foloowerUSer = followerId) follows  a user(followedUser = userId)
exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onCreate(async (snapshot, context) => {
    console.log("Follower craeted ", snapshot.data);

    //   follwed user
    const userId = context.params.userId;
    //   Follower user
    const followerId = context.params.followerId;

    //1) Get followed users(userId) posts
    const followedUserPostsRef = admin
      .firestore()
      .collection("posts")
      .doc(userId)
      .collection("userPosts");

    //2) get the following users timeline
    const timelinePostRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts");

    //3) Get followed users posts
    const querySnapshot = await followedUserPostsRef.get();

    //4)put followed users posts in the timeline of following user
    querySnapshot.forEach((doc) => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostRef.doc(postId).set(postData);
      }
    });
  });

// When a user unfollows  a user(followedUser = userId)
exports.onDeleteFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async (snapshot, context) => {
    console.log("Follwer deleted ", snapshot.id);

    //   follwed user
    const userId = context.params.userId;
    //   Follower user
    const followerId = context.params.followerId;

    //1) get the posts of unfollowed user, from following users timeline
    const timelinePostRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts")
      .where("ownerId", "==", userId);

    const querySnapshot = await timelinePostRef.get();
    querySnapshot.forEach((doc) => {
      if (doc.exists) {
        doc.ref.delete();
      }
    });
  });

//   posts
// 1) create = when post is created , add it to timeline of each follower
exports.onCreatePost = functions.firestore
  .document("posts/{userId}/userPosts/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //1)   get all followers of user making post(post owner)
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    // 2)  add new post to each  followers timeline
    querySnapshot.forEach((doc) => {
      const followerId = doc.id;
      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .set(postCreated);
    });
  });

//   update post
exports.onUpdatePost = functions.firestore
  .document("posts/{userId}/userPosts/{postId}")
  .onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //1)   get all followers of user making post(post owner)
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    // 2)  Update new post to each  followers timeline
    querySnapshot.forEach((doc) => {
      const followerId = doc.id;
      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then((doc) => {
          if (doc.exists) {
            doc.ref.update(postUpdated);
          }
        });
    });
  });

//   delete post
exports.onDeletePost = functions.firestore
  .document("posts/{userId}/userPosts/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    //1)   get all followers of user making post(post owner)
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    // 2)  Update new post to each  followers timeline
    querySnapshot.forEach((doc) => {
      const followerId = doc.id;
      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then((doc) => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });

// Push notifications
exports.onCreateActivitiFeedItem = functions.firestore
  .document("/feed/{userId}/feedItems/{activityFeedItem}")
  .onCreate(async (snapshot, context) => {
    console.log("Acitivity feed item created ", snapshot.data());
    // 1) Get the user to the feed
    const userId = context.params.userId;

    // 2) Ref to the perticular feed wala user
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 3) Once we have user , check if he has notification token
    const androidNotificationToken = doc.data().androidNotificationToken;

    const createdActivityFeedItem = snapshot.data();
    if (androidNotificationToken) {
      // send notifications
      sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
      console.log("No token for user, cant send notification");
    }

    // function for sending notifications
    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      //4) switch body value based of a notification type
      switch (activityFeedItem.type) {
        case "comment":
          body = `${activityFeedItem.username} commented on your post: ${activityFeedItem.commentData}.`;
          break;

        case "like":
          body = `${activityFeedItem.username} liked your post.`;
          break;

        case "follow":
          body = `${activityFeedItem.username} started following you.`;
          break;

        default:
          break;
      }

      // 4) Create message for push notifications
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId },
      };

      // 5)send message with admin.messaging
      admin
        .messaging()
        .send(message)
        .then((response) => {
          // Response is  a messageId string
          console.log("Successfully send message", response);
        })
        .catch((err) => console.log("Error in sending message", err));
    }
  });
