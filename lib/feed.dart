import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/post.dart';
import 'posts.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key, this.durationInDay}) : super(key: key);
  final durationInDay;
  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<Post> postsList = [];
  StreamSubscription? loadDataStream;
  StreamController<Post> updatingStream = StreamController.broadcast();
  @override
  void initState() {
    super.initState();
    initList();
  }

  initList() async {
    if (loadDataStream != null) {
      loadDataStream!.cancel();
      postsList = [];
    }
    loadDataStream = FirebaseFirestore.instance
        .collection('posts')
        .where('time', isEqualTo: widget.durationInDay)
        .snapshots()
        .listen((event) {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            postsList.add(Post.fromMap(
              {...change.doc.data()!, 'updatingStream': updatingStream},
              // 0
            )); // we are adding to a local list when the element is added in firebase collection
            break; //the Post element we will send on pair with updatingStream, because a Post constructor makes a listener on a stream.
          case DocumentChangeType.modified:
            updatingStream.add(Post.fromMap(
              {...change.doc.data()!},
              // 0
            )); // we are sending a modified object in the stream.
            break;
          case DocumentChangeType.removed:
            postsList.remove(Post.fromMap(
              {...change.doc.data()!},
              // 0
            )); // we are removing a Post object from the local list.
            break;
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (loadDataStream != null) {
      loadDataStream!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: ListView.builder(
          itemCount: postsList.length,
          itemBuilder: (context, index) {
            return Posts(
              post: postsList[index],
            );
          }),
    ));
  }
}
