import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AMAR/notification_helper.dart';
import 'dart:async';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to schedule notifications for all medications
  Future<void> scheduleAllMedicationNotifications() async {
  // Get current user
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // Fetch user data
  final userDoc = await _firestore
      .collection('users')
      .doc(currentUser.uid)
      .get();
  
  // Ensure user data exists
  final userData = userDoc.data() ?? {};

  // Fetch medications
  final medicationsSnapshot = await _firestore
      .collection('users')
      .doc(currentUser.uid)
      .collection('medications')
      .get();

  // Schedule notifications for each medication
  for (var doc in medicationsSnapshot.docs) {
    print(doc.data()['selectionOption']);
    await _scheduleMedicationNotifications(
      doc.id, 
      doc.data(), 
      userData
    );
  }
}

  // Internal method to schedule notifications for a specific medication
 Future<void> _scheduleMedicationNotifications(
  String medicationId, 
  Map<String, dynamic> medicationData,
  Map<String, dynamic> userData,
) async {
  // Parse medication details
    final String medicineName = medicationData['selectionOption'] ?? 'Medication';
    final int frequency = medicationData['frequency'] ?? 1;
    final String? startTime = medicationData['startTime'];
    final String? endTime = medicationData['endTime'];
    final DateTime? startDate = medicationData['startDate'] != null 
        ? DateTime.parse(medicationData['startDate']) 
        : null;
    final DateTime? endDate = medicationData['endDate'] != null 
        ? DateTime.parse(medicationData['endDate']) 
        : null;

    // Parse meal timing information
    final mealSelection = medicationData['mealSelection'] ?? {};
    final String mealTiming = mealSelection['beforeOrAfter'] ?? 'Before';
    final Map<String, dynamic> selectedMeals = mealSelection['meals'] ?? {};

    // Validate required fields

  // Generate notification times based on medication type
  List<DateTime> notificationTimes;
  if (medicationData['selectionOption'] == 'Frequency'){
    if (startTime == null || startDate == null || endDate == null) return;
    notificationTimes = _generateFrequencyBasedTimes(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        frequency: frequency
      );
  }
  else{
    if (startDate == null || endDate == null) return;

    notificationTimes = _generateMealBasedTimes(
        startDate: startDate,
        endDate: endDate,
        userData: userData,
        mealSelection: mealSelection
      );
  }
  
  // Schedule notifications
  print(notificationTimes);
  for (var notificationDateTime in notificationTimes) {
  // Validate notification is in the future
  if (notificationDateTime.isAfter(DateTime.now())) {
    await NotificationHelper.scheduleNotificationAtDateTime(
      title: 'Medication Reminder',
      body: _constructNotificationBody(
        medicineName, 
        mealTiming, 
        selectedMeals
      ),
      scheduledDate: notificationDateTime,
      routeName: '/editProfile',
    );
  }
}
}

List<DateTime> _generateFrequencyBasedTimes({
  required DateTime startDate,
  required DateTime endDate,
  required String startTime,
  String? endTime,
  required int frequency,
}) {
  final TimeOfDay parsedStartTime = _parseTimeString(startTime);
  final TimeOfDay? parsedEndTime = endTime != null ? _parseTimeString(endTime) : null;

  List<DateTime> notificationTimes = [];
  DateTime currentDate = startDate;
  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    if (frequency == 1) {
      // Single time notification
      DateTime notificationDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );
      if (notificationDateTime.isAfter(DateTime.now())){
          notificationTimes.add(notificationDateTime);
        };
    } else if (parsedEndTime != null) {
      // Multiple times between start and end times
      DateTime startDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );
      DateTime endDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      int intervalMinutes = (endDateTime.difference(startDateTime).inMinutes / (frequency - 1)).floor();
      
      for (int i = 0; i < frequency; i++) {
        DateTime notificationDateTime = startDateTime.add(Duration(minutes: intervalMinutes * i));
        if (notificationDateTime.isAfter(DateTime.now())){
          notificationTimes.add(notificationDateTime);
        };
      }
    }

    // Move to next interval
    currentDate = currentDate.add(Duration(days: 1));
  }

  return notificationTimes;
}

List<DateTime> _generateMealBasedTimes({
  required DateTime startDate,
  required DateTime endDate,
  required Map<String, dynamic> userData,
  required Map<String, dynamic> mealSelection,
}) {
  final String mealTiming = mealSelection['beforeOrAfter'] ?? 'Before';
  final Map<String, dynamic> selectedMeals = mealSelection['meals'] ?? {};
  final Map<String, String> mealTimes = {
    'breakfast': userData['breakfastTime'] ?? '08:30',
    'lunch': userData['lunchTime'] ?? '13:30',
    'dinner': userData['dinnerTime'] ?? '20:25',
  };

  List<DateTime> notificationTimes = [];
  DateTime currentDate = startDate;

  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    selectedMeals.forEach((mealType, isSelected) {
      if (isSelected && mealTimes.containsKey(mealType)) {
        TimeOfDay mealTime = _parseTimeString(mealTimes[mealType]!);
        DateTime temp = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          mealTime.hour,
          mealTime.minute,
        );

        // Adjust notification time based on meal timing
        if (mealTiming == 'Before') {
          temp = temp.subtract(Duration(minutes: 15));
        } else {
          temp = temp.add(Duration(minutes: 15));
        }

        if (temp.isAfter(DateTime.now())){
          notificationTimes.add(temp);
        }
      }
    });

    currentDate = currentDate.add(Duration(days: 1));
  }

  return notificationTimes;
}


  // Construct detailed notification body
  String _constructNotificationBody(
    String medicineName, 
    String mealTiming, 
    Map<String, dynamic> selectedMeals
  ) {
    // Create a detailed description of when to take the medication
    String mealDescription = selectedMeals.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .join(', ');

    return '$medicineName - $mealTiming $mealDescription';
  }

  // Helper method to parse time string
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Listen to medication changes and update notifications
  //
StreamSubscription<void>? _medicationChangesSubscription;

/// Call this function to start listening to medication changes
void listenToMedicationChanges() {
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    print("User not logged in");
    return;
  }

  _medicationChangesSubscription = _firestore
      .collection('users')
      .doc(currentUser.uid)
      .collection('medications')
      .snapshots()
      .listen(
    (snapshot) async {
      try {
        print("Medications changed. Updating notifications...");
        await scheduleAllMedicationNotifications();
      } catch (e) {
        print("Error updating notifications: $e");
      }
    },
    onError: (error) {
      print("Error listening to medication changes: $error");
    },
  );
}

/// Stop listening to changes when no longer needed
void stopListeningToMedicationChanges() {
  _medicationChangesSubscription?.cancel();
}
}