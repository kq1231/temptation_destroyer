import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/presentation/providers/hobby_provider_refactored.dart';

class HobbyFormScreen extends ConsumerStatefulWidget {
  static const routeNameAdd = '/hobbies/add';
  static const routeNameEdit = '/hobbies/edit';

  final HobbyModel? hobby; // Null for new hobby, non-null for editing

  const HobbyFormScreen({super.key, this.hobby});

  @override
  ConsumerState<HobbyFormScreen> createState() => _HobbyFormScreenState();
}

class _HobbyFormScreenState extends ConsumerState<HobbyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _category;
  late String? _frequencyGoal;
  late int? _durationGoalMinutes;
  late int? _satisfactionRating;

  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();

    // Initialize form values based on whether we're editing an existing hobby
    _isEdit = widget.hobby != null;

    if (_isEdit) {
      _name = widget.hobby!.name;
      _description = widget.hobby!.description ?? '';
      _category = widget.hobby!.category;
      _frequencyGoal = widget.hobby!.frequencyGoal;
      _durationGoalMinutes = widget.hobby!.durationGoalMinutes;
      _satisfactionRating = widget.hobby!.satisfactionRating;
    } else {
      _name = '';
      _description = '';
      _category = HobbyCategory.physical;
      _frequencyGoal = null;
      _durationGoalMinutes = null;
      _satisfactionRating = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Hobby' : 'Add New Hobby'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter hobby name',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!.trim(),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter a description of the hobby',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onSaved: (value) => _description = value?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: HobbyCategory.values.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(_getCategoryName(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                      onSaved: (value) => _category = value!,
                    ),
                    const SizedBox(height: 16),

                    // Frequency goal field
                    TextFormField(
                      initialValue: _frequencyGoal,
                      decoration: const InputDecoration(
                        labelText: 'Frequency Goal (Optional)',
                        hintText: 'e.g., Daily, Weekly, Twice a week',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSaved: (value) => _frequencyGoal = value?.trim(),
                    ),
                    const SizedBox(height: 16),

                    // Duration goal field
                    TextFormField(
                      initialValue: _durationGoalMinutes?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Duration Goal (Minutes, Optional)',
                        hintText: 'Enter time in minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) {
                        if (value != null && value.isNotEmpty) {
                          _durationGoalMinutes = int.tryParse(value);
                        } else {
                          _durationGoalMinutes = null;
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Satisfaction rating
                    if (_isEdit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Satisfaction Rating (Optional)',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [1, 2, 3, 4, 5].map((rating) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _satisfactionRating = rating;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _satisfactionRating == rating
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade200,
                                  ),
                                  child: Text(
                                    rating.toString(),
                                    style: TextStyle(
                                      color: _satisfactionRating == rating
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _satisfactionRating == null
                                  ? 'No rating'
                                  : _getRatingDescription(_satisfactionRating!),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(
                        _isEdit ? 'Update Hobby' : 'Add Hobby',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      if (_isEdit) {
        // Update existing hobby
        ref.read(hobbyNotifierProvider.notifier).updateHobby(
              id: widget.hobby!.id,
              name: _name,
              description: _description.isNotEmpty ? _description : null,
              category: _category,
              frequencyGoal: _frequencyGoal,
              durationGoalMinutes: _durationGoalMinutes,
              satisfactionRating: _satisfactionRating,
            );
      } else {
        // Add new hobby
        ref.read(hobbyNotifierProvider.notifier).addHobby(
              name: _name,
              description: _description.isNotEmpty ? _description : null,
              category: _category,
              frequencyGoal: _frequencyGoal,
              durationGoalMinutes: _durationGoalMinutes,
            );
      }

      // Return to previous screen
      Navigator.of(context).pop();
    }
  }

  String _getCategoryName(String category) {
    if (category == HobbyCategory.physical) return 'Physical';
    if (category == HobbyCategory.mental) return 'Mental';
    if (category == HobbyCategory.social) return 'Social';
    if (category == HobbyCategory.spiritual) return 'Spiritual';
    if (category == HobbyCategory.creative) return 'Creative';
    if (category == HobbyCategory.productive) return 'Productive';
    if (category == HobbyCategory.relaxing) return 'Relaxing';
    return category; // Fallback
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Not enjoyable';
      case 2:
        return 'Somewhat enjoyable';
      case 3:
        return 'Moderately enjoyable';
      case 4:
        return 'Very enjoyable';
      case 5:
        return 'Extremely enjoyable';
      default:
        return '';
    }
  }
}
