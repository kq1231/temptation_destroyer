import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trigger_model.dart';
import '../../providers/trigger_provider.dart';

/// Screen for adding or editing a trigger
class TriggerFormScreen extends ConsumerStatefulWidget {
  /// The trigger to edit (if editing)
  final Trigger? trigger;

  /// Constructor
  const TriggerFormScreen({super.key, this.trigger});

  @override
  ConsumerState<TriggerFormScreen> createState() => _TriggerFormScreenState();
}

class _TriggerFormScreenState extends ConsumerState<TriggerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  TriggerType _selectedType = TriggerType.emotional;
  int _intensity = 5;
  final List<String> _selectedTimes = [];
  final List<int> _selectedDays = [];

  final Map<String, String> _timeOptions = {
    'morning': 'Morning (5am-12pm)',
    'afternoon': 'Afternoon (12pm-5pm)',
    'evening': 'Evening (5pm-9pm)',
    'night': 'Night (9pm-5am)',
  };

  final List<String> _dayOptions = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing trigger, populate the form
    if (widget.trigger != null) {
      _descriptionController.text = widget.trigger!.description;
      _notesController.text = widget.trigger!.notes ?? '';
      _selectedType = widget.trigger!.triggerType ?? TriggerType.emotional;
      _intensity = widget.trigger!.intensity;
      _selectedTimes.addAll(widget.trigger!.activeTimesList);
      _selectedDays.addAll(widget.trigger!.activeDaysList);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    return widget.trigger == null
        ? AppStrings.addTrigger
        : AppStrings.editTrigger;
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _saveTrigger() async {
    if (!_validateForm()) return;

    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    if (widget.trigger == null) {
      // Add new trigger
      await ref.read(triggerProvider.notifier).addTrigger(
            description: description,
            triggerType: _selectedType,
            intensity: _intensity,
            notes: notes.isNotEmpty ? notes : null,
            activeTimes: _selectedTimes.isNotEmpty ? _selectedTimes : null,
            activeDays: _selectedDays.isNotEmpty ? _selectedDays : null,
          );
    } else {
      // Update existing trigger
      final updatedTrigger = Trigger(
        id: widget.trigger!.id,
        triggerId: widget.trigger!.triggerId,
        description: description,
        triggerType: _selectedType,
        intensity: _intensity,
        notes: notes.isNotEmpty ? notes : null,
        activeTimes:
            _selectedTimes.isNotEmpty ? _selectedTimes.join(',') : null,
        activeDays: _selectedDays.isNotEmpty
            ? _selectedDays.map((day) => day.toString()).join(',')
            : null,
        createdAt: widget.trigger!.createdAt,
      );

      await ref.read(triggerProvider.notifier).updateTrigger(updatedTrigger);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleTimeSelection(String time) {
    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
      } else {
        _selectedTimes.add(time);
      }
    });
  }

  void _toggleDaySelection(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Color _getTriggerTypeColor(TriggerType type) {
    switch (type) {
      case TriggerType.emotional:
        return AppColors.emotionalTrigger;
      case TriggerType.situational:
        return AppColors.socialTrigger;
      case TriggerType.temporal:
        return AppColors.timeTrigger;
      case TriggerType.physical:
        return AppColors.locationTrigger;
      case TriggerType.custom:
        return AppColors.customTrigger;
    }
  }

  String _getTriggerTypeLabel(TriggerType type) {
    switch (type) {
      case TriggerType.emotional:
        return AppStrings.triggerEmotion;
      case TriggerType.situational:
        return AppStrings.triggerSocial;
      case TriggerType.temporal:
        return AppStrings.triggerTime;
      case TriggerType.physical:
        return AppStrings.triggerLocation;
      case TriggerType.custom:
        return AppStrings.triggerCustom;
    }
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.triggerType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TriggerType.values.map((type) {
            final isSelected = type == _selectedType;
            final color = _getTriggerTypeColor(type);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? color : color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  _getTriggerTypeLabel(type),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntensitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.triggerIntensity,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('1'),
            Expanded(
              child: Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _intensity.toString(),
                onChanged: (value) {
                  setState(() {
                    _intensity = value.round();
                  });
                },
              ),
            ),
            const Text('10'),
          ],
        ),
        Center(
          child: Text(
            'Selected intensity: $_intensity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _intensity <= 3
                  ? Colors.green
                  : _intensity <= 7
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.triggerTime,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeOptions.entries.map((entry) {
            final isSelected = _selectedTimes.contains(entry.key);

            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                _toggleTimeSelection(entry.key);
              },
              selectedColor:
                  AppColors.timeTrigger.withAlpha((0.3 * 255).round()),
              checkmarkColor: AppColors.timeTrigger,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Days',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_dayOptions.length, (index) {
            final isSelected = _selectedDays.contains(index);

            return FilterChip(
              label: Text(_dayOptions[index]),
              selected: isSelected,
              onSelected: (selected) {
                _toggleDaySelection(index);
              },
              selectedColor:
                  AppColors.timeTrigger.withAlpha((0.3 * 255).round()),
              checkmarkColor: AppColors.timeTrigger,
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final triggerState = ref.watch(triggerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          TextButton(
            onPressed: triggerState.isLoading ? null : _saveTrigger,
            child: const Text(
              AppStrings.save,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: triggerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.triggerDescription,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Type selector
                    _buildTypeSelector(),
                    const SizedBox(height: 24),

                    // Intensity selector
                    _buildIntensitySelector(),
                    const SizedBox(height: 24),

                    // Time selector
                    _buildTimeSelector(),
                    const SizedBox(height: 24),

                    // Day selector
                    _buildDaySelector(),
                    const SizedBox(height: 24),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.triggerNotes,
                        border: OutlineInputBorder(),
                        hintText:
                            'Add any additional details about this trigger',
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: triggerState.isLoading ? null : _saveTrigger,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.trigger == null
                              ? 'Add Trigger'
                              : 'Update Trigger',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
