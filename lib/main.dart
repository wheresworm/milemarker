import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/map_screen.dart';
import 'data/providers/location_provider.dart';
import 'data/providers/route_provider.dart';
import 'core/utils/logger.dart';

void main() async {
  try {
    // Initialize logger
    AppLogger.init(level: LogLevel.info);

    // Load environment variables
    await dotenv.load(fileName: ".env");
    AppLogger.info("Environment loaded successfully");

    runApp(const MyApp());
  } catch (e) {
    AppLogger.severe("Failed to load environment: $e");

    // Show a user-friendly error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error loading app. Please check your configuration.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: MaterialApp(
        title: 'MileMarker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MapScreen(),
      ),
    );
  }
}
