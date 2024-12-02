import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'addImage.dart';
import 'home.dart';

class InfoPage extends StatefulWidget {
  final List<Uint8List> segmentedImages;
  const InfoPage({Key? key, required this.segmentedImages}) : super(key: key);

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late List<Uint8List> _images;
  late List<String> medname;
  late List<String> _selectionOption;
  late List<int> _frequency;
  late List<TimeOfDay?> _startTime;
  late List<TimeOfDay?> _endTime;
  late List<DateTime?> _startDate;
  late List<DateTime?> _endDate;
  final List<List<bool>> _mealSelection = [];
  final List<String> _mealTiming = [];

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.segmentedImages);
    _selectionOption = [];
    _frequency = [];
    _startTime = [];
    _endTime = [];
    medname = [];
    _startDate = [];
    _endDate = [];

    for (int i = 0; i < _images.length; i++) {
      _selectionOption.add('');
      medname.add('');
      _frequency.add(1);
      _startTime.add(null);
      _endTime.add(null);
      _startDate.add(null);
      _endDate.add(null);
      _mealSelection.add([false, false, false]); 
      _mealTiming.add('Before');
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
      _selectionOption.removeAt(index);
      _frequency.removeAt(index);
      _startTime.removeAt(index);
      medname.removeAt(index);
      _endTime.removeAt(index);
      _startDate.removeAt(index);
      _endDate.removeAt(index);
      _mealSelection.removeAt(index);
      _mealTiming.removeAt(index);
    });
  }

  Future<void> _submitImageData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    for (int i = 0; i < _images.length; i++) {
      try {
        final base64Image = base64Encode(_images[i]);
        final imageData = {
          'medname': medname[i],
          'selectionOption': _selectionOption[i],
          'frequency': _frequency[i],
          'startTime': _startTime[i] != null
              ? '${_startTime[i]!.hour}:${_startTime[i]!.minute.toString().padLeft(2, '0')}'
              : null,
          'endTime': _endTime[i] != null
              ? '${_endTime[i]!.hour}:${_endTime[i]!.minute.toString().padLeft(2, '0')}'
              : null,
          'startDate': _startDate[i]?.toIso8601String(),
          'endDate': _endDate[i]?.toIso8601String(),
          'mealSelection': {
            'beforeOrAfter': _mealTiming[i],
            'meals': {
              'breakfast': _mealSelection[i][0],
              'lunch': _mealSelection[i][1],
              'dinner': _mealSelection[i][2],
            },
          },
          'image': base64Image,
        };

        await userDoc.collection('medications').add(imageData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image data saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  void _addNewImage(Uint8List newImage) {
    setState(() {
      _images.add(newImage);
      medname.add('');
      _selectionOption.add('');
      _frequency.add(1);
      _startTime.add(null);
      _endTime.add(null);
      _startDate.add(null);
      _endDate.add(null);
      _mealSelection.add([false, false, false]);
      _mealTiming.add('Before');
    });
  }

  Future<void> _selectDate(
      BuildContext context, int index, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate[index] = picked;
        } else {
          _endDate[index] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segmented Images'),
      ),
      body: _images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No images remaining',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Return to Camera'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.memory(
                              _images[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => _deleteImage(index),
                                tooltip: 'Delete image',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                iconSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                          
                        
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicine Name:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              onChanged: (value) {
                                setState(() {
                                  medname[index] = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter medicine name',
                              ),
                            ),
                            const Text('Choose Option:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Frequency',
                                  groupValue: _selectionOption[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectionOption[index] = value!;
                                    });
                                  },
                                ),
                                const Text('Frequency'),
                                Radio<String>(
                                  value: 'Meal',
                                  groupValue: _selectionOption[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectionOption[index] = value!;
                                    });
                                  },
                                ),
                                const Text('According to Meal'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Date:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () =>
                                            _selectDate(context, index, true),
                                        child: Text(
                                          _startDate[index] != null
                                              ? '${_startDate[index]!.toLocal()}'
                                                  .split(' ')[0]
                                              : 'Select Start Date',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Date:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () =>
                                            _selectDate(context, index, false),
                                        child: Text(
                                          _endDate[index] != null
                                              ? '${_endDate[index]!.toLocal()}'
                                                  .split(' ')[0]
                                              : 'Select End Date',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_selectionOption[index] == 'Frequency') ...[
                              const Text('Frequency:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextFormField(
                                initialValue: _frequency[index].toString(),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _frequency[index] =
                                        int.tryParse(value) ?? 1;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Enter frequency',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Start Time:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                    context: context,
                                    initialTime:
                                        _startTime[index] ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startTime[index] = picked;
                                    });
                                  }
                                },
                                child: Text(
                                    _startTime[index]?.format(context) ??
                                        'Select Start Time'),
                              ),
                              const SizedBox(height: 8),
                              const Text('End Time:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                    context: context,
                                    initialTime:
                                        _endTime[index] ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _endTime[index] = picked;
                                    });
                                  }
                                },
                                child: Text(_endTime[index]?.format(context) ??
                                    'Select End Time'),
                              ),
                            ] else if (_selectionOption[index] == 'Meal') ...[
                              const SizedBox(height: 8),
                              const Text('Timing:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: _mealTiming[index],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _mealTiming[index] = newValue!;
                                  });
                                },
                                items: <String>[
                                  'Before',
                                  'After'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                isExpanded: true,
                              ),
                              const SizedBox(height: 8),
                              const Text('Meals:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _mealSelection[index][0],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _mealSelection[index][0] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Breakfast'),
                                  Checkbox(
                                    value: _mealSelection[index][1],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _mealSelection[index][1] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Lunch'),
                                  Checkbox(
                                    value: _mealSelection[index][2],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _mealSelection[index][2] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Dinner'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 28.0),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Retake'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: () async {
                  final Uint8List? newImage = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddImagePage(),
                    ),
                  );
                  if (newImage != null) {
                    _addNewImage(newImage);
                  }
                },
                child: const Icon(Icons.add, color: Colors.white),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _images.isEmpty
                      ? null
                      : () async {
                          await _submitImageData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Images saved!')),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Home(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}