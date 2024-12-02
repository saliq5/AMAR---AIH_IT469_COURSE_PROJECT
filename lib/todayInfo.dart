import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'edit_reminder_page.dart';

class TodayInfoPage extends StatefulWidget {
  final DateTime date;

  const TodayInfoPage({Key? key, required this.date}) : super(key: key);

  @override
  _TodayInfoPageState createState() => _TodayInfoPageState();
}



class _TodayInfoPageState extends State<TodayInfoPage> {
  User? _user;
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  Map<String, String>? _userProfile;

  final Map<String, IconData> _mealIcons = {
    'breakfast': Icons.breakfast_dining,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserAndLoadReminders();
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    return '$hour:$minute $period';
  }

  String _calculateTimeDifference(String mealTime, bool isBefore) {
    try {
      final parts = mealTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final mealDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      );

      final timeDifference = const Duration(minutes: 15);
      
      final medicineTime = isBefore 
          ? mealDateTime.subtract(timeDifference)
          : mealDateTime.add(timeDifference);
      
      final formattedMedicineTime = 
          '${medicineTime.hour > 12 ? medicineTime.hour - 12 : medicineTime.hour}:'
          '${medicineTime.minute.toString().padLeft(2, '0')} '
          '${medicineTime.hour >= 12 ? 'PM' : 'AM'}';
      
      return formattedMedicineTime;
    } catch (e) {
      return 'Time not available';
    }
  }

  Future<void> _fetchUserAndLoadReminders() async {
    setState(() {
      _isLoading = true;
    });

    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      try {
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        
        if (profileDoc.exists) {
          Map<String, dynamic> profileData = profileDoc.data() as Map<String, dynamic>;
          setState(() {
            _userProfile = {
              'breakfastTime': profileData['breakfastTime'] ?? 'Not set',
              'lunchTime': profileData['lunchTime'] ?? 'Not set',
              'dinnerTime': profileData['dinnerTime'] ?? 'Not set',
            };
          });
        }

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('medications')
            .where('startDate', isLessThanOrEqualTo: widget.date.toIso8601String())
            .where('endDate', isGreaterThanOrEqualTo: widget.date.toIso8601String())
            .get();

        setState(() {
          _reminders = querySnapshot.docs
              .map((doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  })
              .toList();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildMealRow(String mealType, String mealTime, bool isSelected) {
    if (!isSelected) return const SizedBox.shrink();
    
    final formattedTime = _formatTime(mealTime);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            _mealIcons[mealType.toLowerCase()] ?? Icons.restaurant,
            size: 24.sp,
            color: Colors.white,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Meal time: $formattedTime',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimingSection(Map<String, dynamic> reminderData) {
    final meals = reminderData['mealSelection']['meals'] as Map<String, dynamic>;
    final beforeOrAfter = reminderData['mealSelection']['beforeOrAfter'] as String;
    final isBefore = beforeOrAfter.toLowerCase() == 'before';
    
    final backgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.2);
    final textColor = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBefore ? Icons.arrow_upward : Icons.arrow_downward,
                color: textColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '$beforeOrAfter Meals',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(height: 1.h, color: textColor.withOpacity(0.3)),
          SizedBox(height: 8.h),
          if (_userProfile != null) ...[
            _buildMealRow('Breakfast', _userProfile!['breakfastTime']!, meals['breakfast'] ?? false),
            _buildMealRow('Lunch', _userProfile!['lunchTime']!, meals['lunch'] ?? false),
            _buildMealRow('Dinner', _userProfile!['dinnerTime']!, meals['dinner'] ?? false),
          ],
          SizedBox(height: 8.h),
          Divider(height: 1.h, color: textColor.withOpacity(0.3)),
          SizedBox(height: 8.h),
          Text(
            'Take medicine at:',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          ...meals.entries.where((entry) => entry.value == true).map((entry) {
            final mealTime = _userProfile?['${entry.key}Time'] ?? 'Not set';
            final medicineTime = _calculateTimeDifference(mealTime, isBefore);
            return Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '${entry.key}: $medicineTime',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminderData) {
    Uint8List? imageBytes;
    if (reminderData['image'] != null) {
      imageBytes = Uint8List.fromList(base64Decode(reminderData['image']));
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.h),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Type: ${reminderData['selectionOption']}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (reminderData['selectionOption'] == 'Frequency') ...[
                    Text('Frequency: ${reminderData['frequency']} times', style: TextStyle(color: Colors.white70)),
                    if (reminderData['startTime'] != null)
                      Text('Start Time: ${reminderData['startTime']}', style: TextStyle(color: Colors.white70)),
                    if (reminderData['endTime'] != null)
                      Text('End Time: ${reminderData['endTime']}', style: TextStyle(color: Colors.white70)),
                  ] else if (reminderData['selectionOption'] == 'Meal') ...[
                    _buildMealTimingSection(reminderData),
                  ],
                ],
              ),
            ),
            if (imageBytes != null) ...[
              Column(
                children: [
                  Container(
                    width: 100.w,
                    height: 100.h,
                    margin: EdgeInsets.only(left: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade700),
                      image: DecorationImage(
                        image: MemoryImage(imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => _editReminder(reminderData),
                        child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () => _deleteReminder(context, reminderData['id']),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton(
                        onPressed: () => _logMedicineIntake(reminderData),
                        child: Text('Log', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logMedicineIntake(Map<String, dynamic> reminderData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    print("eminder:");
    // Show a dialog to add optional notes
    String? note = await showDialog<String>(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        return AlertDialog(
          title: Text('Log Medicine Intake'),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Add an optional note (optional)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(noteController.text.trim()),
              child: Text('Log Intake'),
            ),
          ],
        );
      },
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_logs')
          .add({
        'medicineName': reminderData['medname'] ?? 'Unnamed Medicine',
        'loggedAt': FieldValue.serverTimestamp(),
        'note': note,
        'reminderType': reminderData['selectionOption'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medicine intake logged successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging medicine intake: $e')),
      );
    }
  }

  Future<void> _editReminder(Map<String, dynamic> reminderData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderPage(reminderData: reminderData),
      ),
    );

    if (result == true) {
      await _fetchUserAndLoadReminders();
    }
  }

  Future<void> _deleteReminder(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('medications')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder deleted successfully')),
      );

      _fetchUserAndLoadReminders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Text('Please log in to view reminders', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminders for ${widget.date.toLocal().toString().split(' ')[0]}',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        centerTitle: true,
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'No reminders to show!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(_reminders[index]);
                    },
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

