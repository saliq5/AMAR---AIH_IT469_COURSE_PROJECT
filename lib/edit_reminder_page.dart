import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditReminderPage extends StatefulWidget {
  final Map<String, dynamic> reminderData;

  const EditReminderPage({Key? key, required this.reminderData}) : super(key: key);

  @override
  _EditReminderPageState createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frequencyController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late String _selectionOption;
  late Map<String, bool> _mealSelection;
  late String _beforeOrAfter;

  @override
  void initState() {
    super.initState();
    _selectionOption = widget.reminderData['selectionOption'];
    _frequencyController = TextEditingController(text: widget.reminderData['frequency']?.toString() ?? '');
    _startTimeController = TextEditingController(text: widget.reminderData['startTime'] ?? '');
    _endTimeController = TextEditingController(text: widget.reminderData['endTime'] ?? '');
    _mealSelection = Map<String, bool>.from(widget.reminderData['mealSelection']['meals']);
    _beforeOrAfter = widget.reminderData['mealSelection']['beforeOrAfter'];
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateReminder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        final updatedData = {
          'selectionOption': _selectionOption,
          if (_selectionOption == 'Frequency') ...{
            'frequency': int.parse(_frequencyController.text),
            'startTime': _startTimeController.text,
            if (int.parse(_frequencyController.text) > 1) 'endTime': _endTimeController.text,
          },
          if (_selectionOption == 'Meal') ...{
            'mealSelection': {
              'meals': _mealSelection,
              'beforeOrAfter': _beforeOrAfter,
            },
          },
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(widget.reminderData['id'])
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder updated successfully')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reminder: $e')),
        );
      }
    }
  }

  Widget _buildFrequencyFields() {
  return Column(
    children: [
      TextFormField(
        controller: _frequencyController,
        decoration: InputDecoration(labelText: 'Frequency'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the frequency';
          }
          final freq = int.tryParse(value);
          if (freq == null || freq <= 0) {
            return 'Frequency must be a positive integer';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {});
        },
      ),
      TextFormField(
        controller: _startTimeController,
        readOnly: true,
        decoration: InputDecoration(labelText: 'Start Time'),
        onTap: () async {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() {
              _startTimeController.text = picked.format(context);
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select the start time';
          }
          return null;
        },
      ),
      if (int.tryParse(_frequencyController.text) != 1)
        TextFormField(
          controller: _endTimeController,
          readOnly: true,
          decoration: InputDecoration(labelText: 'End Time'),
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                _endTimeController.text = picked.format(context);
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select the end time';
            }
            return null;
          },
        ),
    ],
  );
}


  Widget _buildMealSelectionFields() {
    return Column(
      children: [
        ..._mealSelection.entries.map((entry) => CheckboxListTile(
              title: Text(entry.key.capitalize()),
              value: entry.value,
              onChanged: (bool? value) {
                setState(() {
                  _mealSelection[entry.key] = value ?? false;
                });
              },
            )),
        DropdownButtonFormField<String>(
          value: _beforeOrAfter,
          items: ['Before', 'After']
              .map((label) => DropdownMenuItem(
                    child: Text(label),
                    value: label,
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _beforeOrAfter = value!;
            });
          },
          decoration: InputDecoration(labelText: 'Before or After Meal'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Reminder', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).colorScheme.background, Theme.of(context).colorScheme.surface],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              DropdownButtonFormField<String>(
                value: _selectionOption,
                items: ['Frequency', 'Meal']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectionOption = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Reminder Type'),
              ),
              SizedBox(height: 16.h),
              if (_selectionOption == 'Frequency') _buildFrequencyFields(),
              if (_selectionOption == 'Meal') _buildMealSelectionFields(),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _updateReminder,
                child: Text('Update Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}