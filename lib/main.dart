import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/trips_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/controllers/route_controller.dart';
import 'presentation/controllers/meal_stop_controller.dart';
import 'presentation/controllers/places_controller.dart';
import 'presentation/widgets/splash_screen.dart';
import 'presentation/controllers/theme_controller.dart';
import 'core/services/database_service.dart';
import 'core/services/location_service.dart';
import 'core/services/route_service.dart';
import 'core/services/directions_service.dart';
import 'core/services/places_service.dart';
import 'core/services/food_stop_service.dart';
import 'core/services/fuel_planning_service.dart';
import 'core/services/tracking_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MileMarkerApp());
}

class MileMarkerApp extends StatelessWidget {
  const MileMarkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services (lowest level dependencies first)
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        Provider<PlacesService>(
          create: (_) => PlacesService(),
        ),
        Provider<DirectionsService>(
          create: (_) => DirectionsService(),
        ),

        // Services that depend on other services
        ProxyProvider<PlacesService, FoodStopService>(
          create: (context) => FoodStopService(
            placesService: context.read<PlacesService>(),
          ),
          update: (context, placesService, previous) =>
              previous ?? FoodStopService(placesService: placesService),
        ),
        ProxyProvider<PlacesService, FuelPlanningService>(
          create: (context) => FuelPlanningService(
            placesService: context.read<PlacesService>(),
          ),
          update: (context, placesService, previous) =>
              previous ?? FuelPlanningService(placesService: placesService),
        ),

        // Route service with all its dependencies
        ProxyProvider5<DatabaseService, PlacesService, DirectionsService,
            FoodStopService, FuelPlanningService, RouteService>(
          create: (context) => RouteService(
            databaseService: context.read<DatabaseService>(),
            placesService: context.read<PlacesService>(),
            directionsService: context.read<DirectionsService>(),
            foodStopService: context.read<FoodStopService>(),
            fuelPlanningService: context.read<FuelPlanningService>(),
          ),
          update: (context, db, places, directions, food, fuel, previous) =>
              previous ??
              RouteService(
                databaseService: db,
                placesService: places,
                directionsService: directions,
                foodStopService: food,
                fuelPlanningService: fuel,
              ),
        ),

        ProxyProvider2<LocationService, RouteService, TrackingService>(
          create: (context) => TrackingService(
            locationService: context.read<LocationService>(),
            routeService: context.read<RouteService>(),
          ),
          update: (context, locationService, routeService, previous) =>
              previous ??
              TrackingService(
                locationService: locationService,
                routeService: routeService,
              ),
        ),

        // Controllers
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProxyProvider2<RouteService, DirectionsService,
            RouteController>(
          create: (context) => RouteController(
            routeService: context.read<RouteService>(),
            directionsService: context.read<DirectionsService>(),
          ),
          update: (context, routeService, directionsService, previous) =>
              previous ??
              RouteController(
                routeService: routeService,
                directionsService: directionsService,
              ),
        ),
        ChangeNotifierProxyProvider<FoodStopService, MealStopController>(
          create: (context) => MealStopController(
            foodStopService: context.read<FoodStopService>(),
          ),
          update: (context, foodStopService, previous) =>
              previous ?? MealStopController(foodStopService: foodStopService),
        ),
        ChangeNotifierProxyProvider<PlacesService, PlacesController>(
          create: (context) => PlacesController(
            placesService: context.read<PlacesService>(),
          ),
          update: (context, placesService, previous) =>
              previous ?? PlacesController(placesService: placesService),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'MileMarker',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeController.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    TripsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
