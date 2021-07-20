import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:rxdart/rxdart.dart';
import 'package:authentification/GroupMap.dart';
import 'package:authentification/HomePage.dart';

class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Completer<GoogleMapController> mapController = Completer();
  Location location = new Location();
  final geo = Geoflutterfire();
  BehaviorSubject<double> radius = BehaviorSubject();
  late StreamSubscription subscription;
  Set<Marker> customMarkers = {};
  late String _username;
  late String _groupId ;

  late double lat ;
  late double long;



  void _onMapCreated(GoogleMapController controller)
  {
    location.onLocationChanged.listen((position) {
      CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(position.latitude!, position.longitude!))
      );
      GeoFirePoint myLocation = geo.point(
          latitude: position.latitude!, longitude: position.longitude!);
      firestore.collection('groups').doc(_groupId)
          .collection('locations').doc(_auth.currentUser!.uid)
          .set({'name': _username, 'position': myLocation.data});
      });

    mapController.complete(controller);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList){
    customMarkers = {};
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document['position']['geopoint'];
      Marker marker = Marker(
        markerId: MarkerId(document['name']),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: InfoWindow(title: document['name']),
        icon: BitmapDescriptor.defaultMarker,
      );
      setState(() {
        customMarkers.add(marker);
      });
    });
  }

  _setQuery() async {
    var pos = await location.getLocation();
    lat = pos.latitude!;
    long = pos.longitude!;
    GeoFirePoint myLocation = geo.point(latitude: lat, longitude: long);

    var ref = firestore.collection('groups').doc(_groupId).collection('locations');
    print(ref);

    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(new LatLng(lat, long)));

    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: myLocation,
          radius: rad,
          field: 'position',
          strictMode: true
      );
    }).listen(_updateMarkers);

  }

  _updateQuery(value) async {
    setState(() {
      radius.add(value);
    });
    final zoomMap = {100.0: 12.0, 150.0: 11.0, 200: 9.0, 250.0: 8.0, 300:7, 350.0: 6.0, 400.0: 5.0, 450: 4.0, 500.0: 3.0};
    final double zoom =  zoomMap[value] as double;
    final GoogleMapController controller = await mapController.future;
    controller.moveCamera(CameraUpdate.zoomTo(zoom));
    // controller.moveCamera(CameraUpdate.newLatLngZoom(new LatLng(lat, long), zoom));
  }

  Future <void> getUser() async {
    DocumentSnapshot documentSnapshot = await firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (documentSnapshot.exists) {
      _username =  documentSnapshot.get('displayName');
    }else {
      print('User does not exist in the database');
    }
  }

  @override
  void initState() {
    super.initState();
    radius.add(100.0);
    _groupId = grpId;
    _setQuery().whenComplete(() {
      setState(() {
        _username = username;
      });
    }) ;
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
            body:Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(26.8467088, 80.9461592),
                      zoom: 14.4746,
                    ),
                    onMapCreated: _onMapCreated,
                    markers: customMarkers,
                  ),
                  Positioned(
                      bottom: 50,
                      left: 10,
                      child: Slider(
                        min: 100.0,
                        max: 500.0,
                        divisions: 8,
                        value: radius.value,
                        label: 'Radius ${radius.value} kms',
                        activeColor: Colors.blue,
                        inactiveColor: Colors.blue.withOpacity(0.3),
                        onChanged: _updateQuery,
                      )
                  )
                ])
    );
  }



  @override
  void dispose() {
    radius.close();
    subscription.cancel();
    super.dispose();
  }

}


