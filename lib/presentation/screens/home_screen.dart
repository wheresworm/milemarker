import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'route_builder_screen.dart'; // Use relative import since files are in the same directory

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MileMarker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Map', icon: Icon(Icons.map)),
              Tab(text: 'Build Route', icon: Icon(Icons.add_road)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const MapScreen(),
            const RouteBuilderScreen(),
          ],
        ),
      ),
    );
  }
}
