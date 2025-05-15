// lib/presentation/widgets/meal_stop_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/stop.dart';
import '../../core/models/time_window.dart';
import '../../core/models/place.dart';

class MealStopSelector extends StatefulWidget {
  final FoodStop mealStop;
  final List<FoodSuggestion> suggestions;
  final Function(FoodStop) onUpdate;
  final VoidCallback onCancel;

  const MealStopSelector({
    super.key,
    required this.mealStop,
    required this.suggestions,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<MealStopSelector> createState() => _MealStopSelectorState();
}

class _MealStopSelectorState extends State<MealStopSelector> {
  late TimeOfDay _selectedTime;
  late List<FoodPreference> _preferences;
  late Duration _maxDetour;
  int? _selectedSuggestionIndex;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.fromDateTime(
      widget.mealStop.timeWindow?.preferred?.start ?? DateTime.now(),
    );
    _preferences = List.from(widget.mealStop.preferences);
    _maxDetour = widget.mealStop.maxDetour;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${widget.mealStop.mealType.toString().split('.').last.capitalize()} Stop',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),

          // Time selector
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Preferred Time'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
          ),

          // Preferences
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Fast Service'),
                      selected:
                          _preferences.contains(FoodPreference.fastService),
                      onSelected: (selected) => _togglePreference(
                          FoodPreference.fastService, selected),
                    ),
                    FilterChip(
                      label: const Text('Vegetarian'),
                      selected:
                          _preferences.contains(FoodPreference.vegetarian),
                      onSelected: (selected) => _togglePreference(
                          FoodPreference.vegetarian, selected),
                    ),
                    FilterChip(
                      label: const Text('Kid Friendly'),
                      selected:
                          _preferences.contains(FoodPreference.kidFriendly),
                      onSelected: (selected) => _togglePreference(
                          FoodPreference.kidFriendly, selected),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Max detour
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Maximum Detour'),
            subtitle: Text('${_maxDetour.inMinutes} minutes'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _maxDetour.inMinutes.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '${_maxDetour.inMinutes} min',
                onChanged: (value) {
                  setState(() => _maxDetour = Duration(minutes: value.toInt()));
                },
              ),
            ),
          ),

          const Divider(),

          // Suggestions
          if (widget.suggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Restaurant Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.suggestions.length} found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Restaurant list
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = widget.suggestions[index];
                  final isSelected = _selectedSuggestionIndex == index;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color:
                        isSelected ? theme.colorScheme.primaryContainer : null,
                    child: ListTile(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedSuggestionIndex = index);
                      },
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.restaurant, color: Colors.orange),
                      ),
                      title: Text(
                        suggestion.place.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${suggestion.place.rating ?? 'N/A'}'),
                              const SizedBox(width: 8),
                              if (suggestion.place.priceLevel != null)
                                Text(
                                  '\$' *
                                      (suggestion.place.priceLevel!.index + 1),
                                  style: TextStyle(
                                      color: theme.colorScheme.primary),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                '+${suggestion.detourMinutes.toInt()} min',
                                style:
                                    TextStyle(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                          Text(
                            '${suggestion.detourMiles.toStringAsFixed(1)} mi away',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: theme.colorScheme.primary)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _togglePreference(FoodPreference preference, bool selected) {
    setState(() {
      if (selected) {
        _preferences.add(preference);
      } else {
        _preferences.remove(preference);
      }
    });
  }

  void _save() {
    final now = DateTime.now();
    final preferredTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedStop = FoodStop(
      id: widget.mealStop.id,
      name: widget.mealStop.name,
      location: widget.mealStop.location,
      order: widget.mealStop.order,
      mealType: widget.mealStop.mealType,
      preferences: _preferences,
      maxDetour: _maxDetour,
      estimatedDuration: widget.mealStop.estimatedDuration,
      selectedRestaurant: _selectedSuggestionIndex != null
          ? widget.suggestions[_selectedSuggestionIndex!].place
          : widget.mealStop.selectedRestaurant,
      timeWindow: TimeWindow(
        earliest: preferredTime.subtract(const Duration(hours: 1)),
        latest: preferredTime.add(const Duration(hours: 1)),
        preferred: TimeRange(
          start: preferredTime,
          end: preferredTime.add(const Duration(minutes: 30)),
        ),
      ),
      notes: widget.mealStop.notes,
    );

    widget.onUpdate(updatedStop);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
