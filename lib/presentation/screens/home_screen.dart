import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'route_builder_screen.dart';

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
        body: const TabBarView(
          children: [
            MapScreen(),
            RouteBuilderScreen(),
          ],
        ),
      ),
    );
  }
}
