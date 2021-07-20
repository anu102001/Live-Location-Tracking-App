import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


Widget drawer(BuildContext context) {
  return new  Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Treklocation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              textBaseline: TextBaseline.ideographic,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.account_circle),
          title: Text('Profile'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed("/");
          },
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Groups'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed("Groups");
          },
        ),
      ],
    ),
  );
}


late String username;

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late String displayName;
  late String email;
  late User firebaseUser;
  bool isLoggedIn = false;

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed("Start");
      }
    });
  }

  getUser() async {
    firebaseUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot = await firestore.collection('users').doc(_auth.currentUser?.uid).get();
    if (documentSnapshot.exists) {
      email = documentSnapshot.get('email');
      displayName =  documentSnapshot.get('displayName');
      username = displayName;
    } else {
      print('User does not exist in the database');
    }

    setState(() {
      isLoggedIn = true;
    });

  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }


  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    getUser().whenComplete(() {
      setState((){});
    }) ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              appBar: AppBar(
                title: Text('Welcome to Treklocation'),
              ),
        body: Container(
        child: !isLoggedIn
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
              Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
            ])
              ],
            ):
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    "Hello $displayName you are logged in using mail id $email",
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style:ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.fromLTRB(70, 10, 70, 10),
                  ),
                  onPressed: signOut,
                  child: Text('Sign Out',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold)),

                )
              ],
            ),
    ) ,
          drawer: drawer(context)
    );
  }
}
