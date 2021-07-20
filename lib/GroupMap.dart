
import 'package:flutter/material.dart';
import 'package:authentification/Map.dart';


late String grpId;

class GroupMap extends StatelessWidget {
  late final String _title;

  GroupMap({
    required String groupId,
    required String title }) {
    grpId = groupId;
    _title = title;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: Map()
    );
  }
}
