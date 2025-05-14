import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'core/models/trip.dart';
import 'core/services/database_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/tracking_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/places_service.dart';
import 'core/services/route_service.dart';
import 'core/services/directions_service.dart';
import 'core/services/food_stop_service.dart';
import 'core/services/fuel_planning_service.dart';
import 'core/services/route_optimization_service.dart';
import 'core/utils/constants.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/controllers/places_controller.dart';
import 'presentation/controllers/route_controller.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/trips_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/route_builder_screen.dart';
import 'presentation/widgets/animated_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.init();
  await NotificationService().init();
  await PreferencesService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Create services - fixing the constructors based on your actual code
  final directionsService = DirectionsService();
  final placesService = PlacesService();
  final foodStopService = FoodStopService(placesService);
  final fuelPlanningService = FuelPlanningService(placesService: placesService);
  final optimizationService = RouteOptimizationService();
  final routeService = RouteService(
    directionsService: directionsService,
    placesService: placesService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => PlacesController(placesService)),
        ChangeNotifierProvider(
            create: (_) => RouteController(routeService, databaseService)),
      ],
      child: const MileMarkerApp(),
    ),
  );
}

class MileMarkerApp extends StatelessWidget {
  const MileMarkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'MileMarker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeController.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(),
        '/route-builder': (context) => const RouteBuilderScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late AnimationController _bottomSheetController;
  late DraggableScrollableController _draggableController;

  final TrackingService _trackingService = TrackingService();
  final LocationService _locationService = LocationService();

  bool _isTracking = false;
  Trip? _currentTrip;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _draggableController = DraggableScrollableController();
    _initializeServices();
  }

  void _initializeServices() async {
    await _locationService.requestPermissions();
    _locationService.locationStream.listen((location) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTracking() async {
    HapticFeedback.lightImpact();

    if (_isTracking) {
      // Stop tracking
      await _trackingService.stopTracking();
      _fabAnimationController.reverse();
    } else {
      // Start tracking
      await _trackingService.startTracking();
      _fabAnimationController.forward();
    }

    setState(() {
      _isTracking = !_isTracking;
      _currentTrip = _trackingService.currentTrip;
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _bottomSheetController.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MapScreen(
            isTracking: _isTracking,
            currentTrip: _currentTrip,
            currentLocation: _currentLocation,
            onToggleTracking: _toggleTracking,
            onPlanRoute: () {
              Navigator.pushNamed(context, '/route-builder');
            },
            fabAnimationController: _fabAnimationController,
            bottomSheetController: _bottomSheetController,
          ),
          const TripsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        animationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
