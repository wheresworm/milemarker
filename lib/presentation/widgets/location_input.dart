import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/places_service.dart';
import '../../core/utils/logger.dart';

class LocationInput extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(String address, double lat, double lng) onLocationSelected;

  const LocationInput({
    super.key,
    required this.label,
    this.initialValue,
    required this.onLocationSelected,
  });

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  final TextEditingController _controller = TextEditingController();
  final PlacesService _placesService = PlacesService();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getSuggestions(String input) async {
    if (input.length < 3) return;

    setState(() {
      _isLoading = true;
    });

    final suggestions = await _placesService.getPlaceSuggestions(input);

    setState(() {
      _predictions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
      _controller.text = prediction['description'];
    });

    final details = await _placesService.getPlaceDetails(placeId);

    if (details != null && details.containsKey('geometry')) {
      final location = details['geometry']['location'];
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;

      widget.onLocationSelected(prediction['description'], lat, lng);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  13,
                ), // Use withAlpha instead of withOpacity
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ), // Fixed the a16 typo
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.search, color: theme.primaryColor),
                      onPressed: () => _getSuggestions(_controller.text),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            onChanged: (value) {
              if (value.length >= 3) {
                _getSuggestions(value);
              } else {
                setState(() {
                  _predictions = [];
                  _showSuggestions = false;
                });
              }
            },
            onTap: () {
              if (_predictions.isNotEmpty) {
                setState(() {
                  _showSuggestions = true;
                });
              }
            },
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    26,
                  ), // Use withAlpha instead of withOpacity
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      prediction['description'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: theme.primaryColor,
                    ),
                    onTap: () => _selectPrediction(prediction),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
