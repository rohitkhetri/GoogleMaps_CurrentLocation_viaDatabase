import 'package:flutter/material.dart';
import 'db_helper.dart';

class ViewLocationsScreen extends StatefulWidget {
  @override
  _ViewLocationsScreenState createState() => _ViewLocationsScreenState();
}

class _ViewLocationsScreenState extends State<ViewLocationsScreen> {
  late Future<List<Map<String, dynamic>>> _locations;

  @override
  void initState() {
    super.initState();
    _locations = DBHelper().getLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Locations"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _locations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No locations saved"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var location = snapshot.data![index];
                return ListTile(
                  title: Text(location['address']),
                  subtitle: Text(
                    "Lat: ${location['latitude']}, Long: ${location['longitude']}\nDate: ${location['date_time']}",
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
