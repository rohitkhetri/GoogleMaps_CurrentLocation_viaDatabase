import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;

import 'db_helper.dart';
import 'view_locationlist.dart';
import 'main.dart';
class googleMapScreen extends StatefulWidget {

  @override
  _googleMapScreen createState() => _googleMapScreen();
}

class _googleMapScreen extends State<googleMapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  loc.Location location = loc.Location();
  LatLng? _latLng;
  Set<Marker> _markers = {};
  bool servicestatus = false;
  bool haspermission = false;
  double lat = 0.0;
  double long = 0.0;
  String address = "Searching address...";
  String formattedDateTime = "";

  CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    getLocation();
    location.onLocationChanged.listen((loc.LocationData currentLocation){
      _onLocationChanged(currentLocation);
    });
  }

  Future<void> getLocation() async {
    //loc.Location location = loc.Location();
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;
    //loc.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // _locationData = await location.getLocation();
    //
    // setState(() {
    //   servicestatus = _serviceEnabled;
    //   haspermission = _permissionGranted == loc.PermissionStatus.granted;
    //   _latLng = LatLng(_locationData.latitude!, _locationData.longitude!);
    //   lat = _locationData.latitude!;
    //   long = _locationData.longitude!;
    //   _kGooglePlex = CameraPosition(
    //     target: _latLng!,
    //     zoom: 14.4746,
    //   );
    //   _markers.add(
    //     Marker(
    //       markerId: MarkerId("current_location"),
    //       position: _latLng!,
    //       icon: BitmapDescriptor.defaultMarker,
    //     ),
    //   );
    // });

    // _getAddress(_latLng!.latitude, _latLng!.longitude);
    //
    // final GoogleMapController controller = await _controller.future;
    // controller.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));

    loc.LocationData _locationData = await location.getLocation();
    _onLocationChanged(_locationData);

  }

  Future<void> _onLocationChanged(loc.LocationData currentLocation) async {
    setState(() {
      _latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      lat = currentLocation.latitude!;
      long = currentLocation.longitude!;
      _kGooglePlex = CameraPosition(
        target: _latLng!,
        zoom: 14.4746,
      );
      _markers.add(
        Marker(
          markerId: MarkerId("current_location"),
          position: _latLng!,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });

    _getAddress(_latLng!.latitude, _latLng!.longitude);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
  }

  Future<void> _getAddress(double lat, double long) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, long);
      geo.Placemark place = placemarks[0];
      String currentAddress = "${place.street},${place.subLocality}, ${place.country}, ${place.postalCode}";

      setState(() {
        address = currentAddress;
        formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });

      // Save location to database
      await DBHelper().insertLocation(lat, long, currentAddress, formattedDateTime);
    } catch (e) {
      setState(() {
        //address = "Unable to get address";
      });
    }
  }

  void _handleTap(LatLng tappedPoint) async {
    _latLng = tappedPoint;
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId("tapped_location"),
          position: _latLng!,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      lat = tappedPoint.latitude;
      long = tappedPoint.longitude;
    });

    await _getAddress(_latLng!.latitude, _latLng!.longitude);
  }

  // void _onMenuItemSelected(String choice) {
  //   switch (choice) {
  //     case 'View Locations':
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => ViewLocationsScreen()),
  //       );
  //       break;
  //   // Add more cases for other menu items if needed
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Google Map'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );                },
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Map'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => googleMapScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('View Locations'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewLocationsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                markers: _markers,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                onTap: _handleTap,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Longitude: $long", style: TextStyle(fontSize: 16)),
                  Text("Latitude: $lat", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  Text("Address: $address", style: TextStyle(fontSize: 16)),
                  Text("Date: $formattedDateTime", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => ViewLocationsScreen()),
                  //     );
                  //   },
                  //   child: Text("View Locations"),
                  // ),
                ],

              ),
            ),
          ],
        ),
      ),
    );
  }
}