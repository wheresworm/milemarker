// lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'utils/logger.dart';
import 'screens/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize centralized logging
  AppLogger.init();
  AppLogger.info('Environment variables loaded, starting app.');

  runApp(const MileMarkerApp());
}

class MileMarkerApp extends StatelessWidget {
  const MileMarkerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MileMarker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
      home: const MileMarkerHome(),
    );
  }
}

class MileMarkerHome extends StatefulWidget {
  const MileMarkerHome({Key? key}) : super(key: key);

  @override
  State<MileMarkerHome> createState() => _MileMarkerHomeState();
}

class _MileMarkerHomeState extends State<MileMarkerHome> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _mpgController = TextEditingController();
  final _tankController = TextEditingController();

  List<String> _autocompleteSuggestions = [];
  TextEditingController? _activeAutocompleteController;
  Timer? _debounceTimer;

  TimeOfDay? _departureTime;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _startController.dispose();
    _endController.dispose();
    _mpgController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutocomplete(
    String input,
    TextEditingController controller,
  ) async {
    if (input.isEmpty) {
      setState(() {
        _autocompleteSuggestions.clear();
        _activeAutocompleteController = null;
      });
      return;
    }

    AppLogger.fine('Autocomplete request for "$input"');

    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      AppLogger.warning('API key is missing.');
      return;
    }

    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {'input': input, 'key': apiKey, 'components': 'country:us'},
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>;
        setState(() {
          _autocompleteSuggestions =
              predictions
                  .map((p) => p['description'] as String)
                  .where((d) => d.isNotEmpty)
                  .toList();
          _activeAutocompleteController = controller;
        });
        AppLogger.fine(
          'Received ${_autocompleteSuggestions.length} suggestions',
        );
      } else {
        AppLogger.warning('Autocomplete HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.severe('Autocomplete fetch error: $e');
    }
  }

  void _onAutocompleteChanged(String value, TextEditingController controller) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchAutocomplete(value, controller);
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) return;
    setState(() => _departureTime = time);
  }

  Widget _autocompleteField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          onChanged: (val) => _onAutocompleteChanged(val, controller),
        ),
        if (_activeAutocompleteController == controller &&
            _autocompleteSuggestions.isNotEmpty)
          ..._autocompleteSuggestions.map(
            (s) => ListTile(
              title: Text(s),
              onTap: () {
                setState(() {
                  controller.text = s;
                  _autocompleteSuggestions.clear();
                  _activeAutocompleteController = null;
                });
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MileMarker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _autocompleteField(
              label: 'Start Location',
              icon: Icons.location_on,
              controller: _startController,
            ),
            const SizedBox(height: 12),
            _autocompleteField(
              label: 'Destination',
              icon: Icons.flag,
              controller: _endController,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Departure: ${_departureTime?.format(context) ?? 'Now'}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _showAdvanced
                    ? 'Hide Advanced Settings'
                    : 'Show Advanced Settings',
              ),
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _mpgController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Vehicle MPG',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tankController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tank Range (miles)',
                  prefixIcon: Icon(Icons.speed),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Plan My Trip'),
              onPressed: () {
                final start = _startController.text.trim();
                final end = _endController.text.trim();
                if (start.isEmpty || end.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both locations'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => MapScreen(startAddress: start, endAddress: end),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
