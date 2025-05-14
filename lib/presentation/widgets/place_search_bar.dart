import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/places_controller.dart';
import '../../core/models/place.dart' as place_model;

class PlaceSearchBar extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;
  final String hintText;
  final Color? fillColor;
  final bool showSuggestions;
  final bool isDestination;

  const PlaceSearchBar({
    Key? key,
    required this.onLocationSelected,
    this.hintText = 'Search location',
    this.fillColor,
    this.showSuggestions = true,
    this.isDestination = false,
  }) : super(key: key);

  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && widget.showSuggestions;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placesController = context.watch<PlacesController>();

    return Container(
      decoration: BoxDecoration(
        color: widget.fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  widget.isDestination
                      ? Icons.location_on
                      : Icons.circle_outlined,
                  color: widget.isDestination
                      ? Colors.red
                      : theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        placesController.searchPlaces(value);
                      }
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      placesController.clearPlaces();
                      _focusNode.unfocus();
                    },
                  ),
              ],
            ),
          ),
          if (_showSuggestions && placesController.searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: placesController.searchResults.length,
                itemBuilder: (context, index) {
                  final place = placesController.searchResults[index];
                  return _buildPlaceSuggestion(place);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceSuggestion(place_model.Place place) {
    return InkWell(
      onTap: () {
        _searchController.text = place.name;
        widget.onLocationSelected(place.location, place.name);
        _focusNode.unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (place.address != null)
                    Text(
                      place.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
