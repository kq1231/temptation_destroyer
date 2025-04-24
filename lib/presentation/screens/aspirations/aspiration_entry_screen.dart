import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';
import 'package:temptation_destroyer/presentation/providers/aspiration_provider_refactored.dart';
import 'package:temptation_destroyer/presentation/widgets/app_loading_indicator.dart';

class AspirationEntryScreen extends ConsumerStatefulWidget {
  static const routeName = '/aspirations/entry';

  final AspirationModel?
      aspiration; // If provided, we're editing an existing aspiration

  const AspirationEntryScreen({super.key, this.aspiration});

  @override
  ConsumerState<AspirationEntryScreen> createState() =>
      _AspirationEntryScreenState();
}

class _AspirationEntryScreenState extends ConsumerState<AspirationEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _duaController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = AspirationCategory.personal;
  bool _isAchieved = false;
  DateTime? _targetDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    if (widget.aspiration != null) {
      _isEditing = true;
      _duaController.text = widget.aspiration!.dua;
      if (widget.aspiration!.note != null) {
        _noteController.text = widget.aspiration!.note!;
      }

      _selectedCategory = widget.aspiration!.category;
      _isAchieved = widget.aspiration!.isAchieved;
      _targetDate = widget.aspiration!.targetDate;
    }
  }

  @override
  void dispose() {
    _duaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncAspirationState = ref.watch(aspirationNotifierProvider);

    return asyncAspirationState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Aspiration' : 'Add New Aspiration'),
        ),
        body: const AppLoadingIndicator(),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Aspiration' : 'Add New Aspiration'),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (aspirationState) => Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Aspiration' : 'Add New Aspiration'),
        ),
        body: aspirationState.isLoading
            ? const AppLoadingIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dua/Text field
                      TextFormField(
                        controller: _duaController,
                        decoration: const InputDecoration(
                          labelText: 'Dua or Aspiration',
                          hintText: 'Enter your dua or aspiration',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your dua or aspiration';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: AspirationCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Target date selector
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Target Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _targetDate == null
                                    ? 'No date selected'
                                    : _formatDate(_targetDate!),
                                style: TextStyle(
                                  color: _targetDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_targetDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _targetDate = null;
                                        });
                                      },
                                    ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes field
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any additional notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Achievement checkbox
                      CheckboxListTile(
                        title: const Text('Already Achieved'),
                        value: _isAchieved,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _isAchieved = value;
                            });
                          }
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed:
                            aspirationState.isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'Update Aspiration' : 'Add Aspiration',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _getCategoryName(String category) {
    if (category == AspirationCategory.personal) return 'Personal';
    if (category == AspirationCategory.family) return 'Family';
    if (category == AspirationCategory.career) return 'Career';
    if (category == AspirationCategory.spiritual) return 'Spiritual';
    if (category == AspirationCategory.health) return 'Health';
    if (category == AspirationCategory.social) return 'Social';
    if (category == AspirationCategory.financial) return 'Financial';
    if (category == AspirationCategory.customized) return 'Custom';
    return category; // Fallback
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final dua = _duaController.text.trim();
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (_isEditing && widget.aspiration != null) {
        // Update existing aspiration
        await ref.read(aspirationNotifierProvider.notifier).updateAspiration(
              id: widget.aspiration!.id,
              dua: dua,
              category: _selectedCategory,
              isAchieved: _isAchieved,
              targetDate: _targetDate,
              note: note,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aspiration updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Add new aspiration
        await ref.read(aspirationNotifierProvider.notifier).addAspiration(
              dua: dua,
              category: _selectedCategory,
              isAchieved: _isAchieved,
              targetDate: _targetDate,
              note: note,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aspiration added successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }
}
