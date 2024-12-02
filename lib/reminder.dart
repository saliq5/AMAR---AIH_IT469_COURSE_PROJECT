import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'todayInfo.dart';

class ViewRemindersPage extends StatefulWidget {
  const ViewRemindersPage({Key? key}) : super(key: key);

  @override
  _ViewRemindersPageState createState() => _ViewRemindersPageState();
}

class _ViewRemindersPageState extends State<ViewRemindersPage> {
  // final User? _currentUser = FirebaseAuth.instance.currentUser;
  DateTime _selectedDate = DateTime.now();

  void _onDateSelected(DateTime date, DateTime _) {
    setState(() {
      _selectedDate = date;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodayInfoPage(date: _selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Medication Reminders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Calendar Widget
          TableCalendar(
            firstDay: DateTime(DateTime.now().year, DateTime.now().month - 3),
            lastDay: DateTime(DateTime.now().year, DateTime.now().month + 3),
            focusedDay: _selectedDate,
            calendarFormat: CalendarFormat.month,
            onDaySelected: _onDateSelected,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
          ),
        ],
      ),
    );
  }
}
