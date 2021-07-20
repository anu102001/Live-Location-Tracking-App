import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:authentification/HomePage.dart';


class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController _searchQuery, _groupName;
  bool _isSearching = false;
  bool _isLoading = false;
  String searchQuery = "Search query";
  late String _username ;
  List<String> _usernames = <String>[];
  List<String> _selectedUsernames= <String> [];


  void _startSearch() {
    ModalRoute.of(context)!.addLocalHistoryEntry(new LocalHistoryEntry(onRemove: _stopSearching));
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _isSearching = false;
      _isLoading = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQuery.clear();
      updateSearchQuery("Search query");
    });
  }

  Widget _buildTitle(BuildContext context) {
    var horizontalTitleAlignment = CrossAxisAlignment.start;

    return new InkWell(
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: horizontalTitleAlignment,
          children: <Widget>[
            const Text('Search box'),
          ],
        ),
      ),
      onTap: _startSearch
    );
  }

  Future <void> getUser() async {
    DocumentSnapshot documentSnapshot = await firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (documentSnapshot.exists) {
      _username =  documentSnapshot.get('displayName');
    }else {
      print('User does not exist in the database');
    }
  }


  Widget _buildSearchField() {
    return new TextField(
      controller: _searchQuery,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search Username',
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.white30),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: updateSearchQuery,
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _isLoading = true;
    });

    int i = 0;
    _usernames.clear();
    firestore.collection('users')
        .where('displayName', isEqualTo: newQuery)
        .get()
        .then((snapshot) {
      setState(() {
        snapshot.docs.forEach((element) {
          if (element['displayName'] != _username) {
            if (!_usernames.contains(element['displayName'])) {
              _usernames.insert(i, element ['displayName']);
              i++;
            }
          }
        });
      });
      _isLoading = false;
    });

  }

  _deleteSelected(String label){
    setState(() {
      _selectedUsernames.remove(label);
    });

  }

  Future<void> _createGroup() async {
    _selectedUsernames.insert(_selectedUsernames.length, _username);
    Map<String, dynamic> groupsMap = {
       'groupName': _groupName.text,
      'users': _selectedUsernames,
    };

    try{
      await firestore.collection('groups').add(groupsMap);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar (content: Text('Group created')));

      setState(() {
        _selectedUsernames.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to create group $e')));
    }
    Navigator.of(context).pushReplacementNamed("Groups");
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
            },
        ),
      ];
    }

    return <Widget>[
      new IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
    ];
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      labelPadding: EdgeInsets.all(1.0),
      avatar: CircleAvatar(
        backgroundColor: Colors.black,
        child: Text(label[0].toUpperCase())
      ),
      label: Text(
        label,
        style:TextStyle(
          color: Colors.white,
        ),
      ),
      deleteIcon: Icon(Icons.close),
      onDeleted: () => _deleteSelected(label),
      backgroundColor: color,
      elevation: 10.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(6.0),
    );
  }

  Widget _buildPopupDialog(BuildContext context) {
    _groupName = new TextEditingController();
    return new AlertDialog(
      title: const Text('Enter Group Name'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
          controller: _groupName,
          autofocus: true,
          style: const TextStyle(color: Colors.black, fontSize: 20.0),
        )
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed:_createGroup,
          style: TextButton.styleFrom(
            primary: Colors.blue,
          ),
          child: Text('Submit'),
        ),
      ],
    );
  }


  @override
  void initState() {
    super.initState();
    getUser().whenComplete(() {
      setState(() {
      });
    }) ;
    _searchQuery = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: _isSearching
            ? _buildSearchField()
            : _buildTitle(context),
        actions: _buildActions(),
      ),
        body:_isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical:4.0, horizontal: 10.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: _selectedUsernames
                              .map((item) => _buildChip(item, Colors.green))
                              .toList()
                              .cast<Widget>()),
                    ),
                  ),
                  _selectedUsernames.isEmpty
                      ? Divider(thickness: 0.0, height: 0, color: Colors.white,)
                  : Divider(thickness: 2.0, height: 0,),
                  ListView.builder(
                     itemCount: _usernames.length,
                     scrollDirection: Axis.vertical,
                     shrinkWrap: true,
                     itemBuilder: (context, index){
                        return ListTile(
                          title: Text('${_usernames[index]}'),
                          onTap: () {
                            setState(() {
                              if (!_selectedUsernames.contains(_usernames[index])) {
                                _selectedUsernames.add(_usernames[index]);
                              }
                            });
                          },
                        );
                  },
              ),
          ]
        ),
      drawer: drawer(context),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => _buildPopupDialog(context),
            );
          },
        child: const Icon(Icons.done),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
