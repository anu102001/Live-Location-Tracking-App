import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:authentification/HomePage.dart';
import 'package:authentification/GroupMap.dart';

class Groups extends StatefulWidget {
  @override
  _GroupsState createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late String _username;

  getUser() async {
    _username = '' ;
    DocumentSnapshot documentSnapshot = await firestore.collection('users').doc(_auth.currentUser?.uid).get();
    if (documentSnapshot.exists) {
        _username =  documentSnapshot.get('displayName');
    } else {
      print('User does not exist in the database');
    }
  }

  @override
  void initState() {
    super.initState();
    getUser().whenComplete(() {
      setState((){});
    }) ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: StreamBuilder(
                  stream: firestore.collection('groups').where('users', arrayContains: _username).snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                    if(!snapshot.hasData){
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: snapshot.data!.docs.map((element) {
                        return Container(
                            height: MediaQuery.of(context).size.height / 8,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                color: Colors.green,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text(
                                            element['groupName'],
                                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight:FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                          element["users"].join(",  "),
                                          style: TextStyle(color: Colors.cyanAccent,)
                                      ),
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => GroupMap(
                                            groupId: element.id.toString(),
                                            title: element['groupName'].toString(),
                                          ),
                                        ),
                                        );
                                        },
                                    )
                                  ]
                                )
                              )
                            )
                        );
                      }).toList(),
                    );
                    },
              )
            )
          ]
        )
      ),
      drawer: drawer(context),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed("Search");
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),

    );
  }
}
