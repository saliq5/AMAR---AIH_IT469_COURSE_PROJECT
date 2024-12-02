import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:AMAR/more.dart';
import 'package:AMAR/edit_profile.dart';
import 'package:AMAR/profile.dart';
import 'package:AMAR/camera.dart';
import 'package:AMAR/reminder.dart';
import 'medilog.dart';
import 'dart:typed_data';
import 'dart:convert';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}


class _HomeState extends State<Home> {
  late String welcomeMessage = 'Welcome Back';
  late String userEmail = '';
  late String firstName = '';
  late String lastName = '';
  late String breakfastTime = '';
  late String lunchTime = '';
  late String dinnerTime = '';
  Map<String, dynamic>? nextMedicine;
  Duration timeLeft = Duration.zero;
  bool isLoading = true;
  int _currentIndex = 0;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Duration _getTimeLeft(String time) {
  //   final now = DateTime.now();
  //   final parts = time.split(':');
  //   final medicineTime = DateTime(
  //     now.year,
  //     now.month,
  //     now.day,
  //     int.parse(parts[0]),
  //     int.parse(parts[1]),
  //   );

  //   if (medicineTime.isBefore(now)) {
  //     return Duration.zero; // Time has passed
  //   }

  //   return medicineTime.difference(now);
  // }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          firstName = userData['firstName'] ?? '';
          lastName = userData['lastName'] ?? '';
          userEmail = user.email ?? 'User';
          breakfastTime = userData['breakfastTime'] ?? '8:00';
          lunchTime = userData['lunchTime'] ?? '13:00';
          dinnerTime = userData['dinnerTime'] ?? '20:00';

          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            welcomeMessage =
                'Welcome Back, \n${firstName.isNotEmpty ? firstName : ''} ${lastName.isNotEmpty ? lastName : ''}'
                    .trim();
          } else {
            welcomeMessage = 'Welcome Back, $userEmail';
          }

        } else {
          userEmail = user.email ?? 'User';
          welcomeMessage = 'Welcome Back, $userEmail';
        }
      } else {
        welcomeMessage = 'Welcome Back, User';
      }
    } catch (e) {
      print('Failed to fetch user data: $e');
      welcomeMessage = 'Welcome Back, User';
    }

    setState(() {
      isLoading = false;
    });
  }

  // Future<void> _fetchNextMedicine(String userId) async {
  //   try {
  //     final medications = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(userId)
  //         .collection('medications')
  //         .get();

  //     final now = DateTime.now();
  //     DateTime? nearestTime;
  //     Map<String, dynamic>? nearestMedicine;

  //     for (var doc in medications.docs) {
  //       final data = doc.data();
  //       DateTime? medicineTime;

  //       if (data['selectionOption'] == 'Frequency') {
  //         if (data['startTime'] != null) {
  //           final parts = (data['startTime'] as String).split(':');
  //           medicineTime = DateTime(now.year, now.month, now.day,
  //               int.parse(parts[0]), int.parse(parts[1]));
  //         }
  //       } else if (data['selectionOption'] == 'Meal') {
  //         final beforeOrAfter = data['mealSelection']['beforeOrAfter'];
  //         final meals = data['mealSelection']['meals'] as Map<String, dynamic>;

  //         String? nearestMealTime;
  //         if (meals['breakfast'] == true) {
  //           nearestMealTime = breakfastTime;
  //         }
  //         if (meals['lunch'] == true &&
  //             _compareTime(lunchTime, nearestMealTime)) {
  //           nearestMealTime = lunchTime;
  //         }
  //         if (meals['dinner'] == true &&
  //             _compareTime(dinnerTime, nearestMealTime)) {
  //           nearestMealTime = dinnerTime;
  //         }

  //         if (nearestMealTime != null) {
  //           final parts = nearestMealTime.split(':');
  //           medicineTime = DateTime(now.year, now.month, now.day,
  //               int.parse(parts[0]), int.parse(parts[1]));

  //           if (beforeOrAfter == 'After') {
  //             medicineTime = medicineTime.add(Duration(minutes: 30));
  //           }
  //         }
  //       }

  //       if (medicineTime != null && medicineTime.isAfter(now)) {
  //         if (nearestTime == null || medicineTime.isBefore(nearestTime)) {
  //           nearestTime = medicineTime;
  //           nearestMedicine = data;
  //         }
  //       }
  //     }

  //     if (nearestTime != null) {
  //       setState(() {
  //         nextMedicine = nearestMedicine;
  //         timeLeft = nearestTime!.difference(now);
  //       });
  //     }
  //   } catch (e) {
  //     print('Failed to fetch next medicine: $e');
  //   }
  // }

  bool _compareTime(String time, String? currentNearest) {
    if (currentNearest == null) return true;
    final now = DateTime.now();
    final parts1 = time.split(':');
    final parts2 = currentNearest.split(':');
    final time1 = DateTime(now.year, now.month, now.day, int.parse(parts1[0]),
        int.parse(parts1[1]));
    final time2 = DateTime(now.year, now.month, now.day, int.parse(parts2[0]),
        int.parse(parts2[1]));
    return time1.isBefore(time2);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > Duration.zero) {
          timeLeft -= Duration(seconds: 1);
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicineLogPage(),
        ),
      );
    },
    child: Icon(Icons.medical_services_outlined),
    tooltip: 'Medicine Logs',
  ),
      appBar: AppBar(
        title: Text(
          'AMAR',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Image.asset(
              'assets/images/amar_logo.png',
              height: 30.h,
            ),
          ),
        ],
        leading: IconButton(
          icon:
              Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.h),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeMessage,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[300],
                        ),
                      ),

                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditProfileScreen()),
                          );
                          if (result == true) {
                            await _fetchUserData();
                          }
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary, // Replaces 'primary'
                          foregroundColor: Colors.white, // Replaces 'onPrimary'
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildMedicationReminders(),
                    ],
                  ),
                  
          ),
        ),
      
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MorePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraPage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildMedicationReminders() {
    return Expanded(
      child: ListView(
        children: [
          _buildMedicinePlanCard(),
          _buildNextMedicineCard(),
          // _buildReminderCard('Breakfast', breakfastTime, Icons.wb_sunny),
          // _buildReminderCard('Lunch', lunchTime, Icons.wb_cloudy),
          // _buildReminderCard('Dinner', dinnerTime, Icons.nights_stay),
        ],
      ),
    );
  }

  Widget _buildNextMedicineCard() {
    if (nextMedicine == null) {
      return SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        _showNextMedicinePopup(context, nextMedicine!);
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(Icons.medical_services,
              color: Theme.of(context).colorScheme.primary, size: 30.sp),
          title: Text(
            'Next Medicine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            nextMedicine!['selectionOption'] == 'Frequency'
                ? nextMedicine!['startTime']
                : 'Based on Meal',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14.sp,
            ),
          ),
          trailing: Text(
            _formatDuration(timeLeft),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinePlanCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.medical_services,
            color: Theme.of(context).colorScheme.primary, size: 30.sp),
        title: Text(
          "Medicine Plan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewRemindersPage()),
          );
        },
      ),
    );
  }

  // Widget _buildReminderCard(String title, String time, IconData icon) {
  //   return Card(
  //     margin: EdgeInsets.only(bottom: 16.h),
  //     color: Theme.of(context).colorScheme.surface,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: ListTile(
  //       leading: Icon(icon,
  //           color: Theme.of(context).colorScheme.primary, size: 30.sp),
  //       title: Text(
  //         title,
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontSize: 18.sp,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       subtitle: Text(
  //         time,
  //         style: TextStyle(
  //           color: Colors.grey[300],
  //           fontSize: 14.sp,
  //         ),
  //       ),
  //       trailing: Text(
  //         _formatDuration(_getTimeLeft(time)),
  //         style: TextStyle(
  //           color: Theme.of(context).colorScheme.primary,
  //           fontWeight: FontWeight.w600,
  //           fontSize: 14.sp,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showNextMedicinePopup(
      BuildContext context, Map<String, dynamic> medicineData) {
    Uint8List? imageBytes;
    if (medicineData['image'] != null &&
        (medicineData['image'] as String).isNotEmpty) {
      try {
        imageBytes = Uint8List.fromList(base64Decode(medicineData['image']));
      } catch (e) {
        debugPrint('Error decoding image: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  if (imageBytes != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          imageBytes,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Icon(Icons.broken_image,
                            size: 50.sp, color: Colors.grey),
                        SizedBox(height: 8.h),
                        Text(
                          'No Image Available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16.h),
                  Text(
                    'Medicine Details',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (medicineData['selectionOption'] == 'Frequency') ...[
                    _buildPopupDetailRow(
                        'Type', medicineData['selectionOption']),
                    if (medicineData['startTime'] != null)
                      _buildPopupDetailRow(
                          'Start Time', medicineData['startTime']),
                    if (medicineData['endTime'] != null)
                      _buildPopupDetailRow('End Time', medicineData['endTime']),
                    if (medicineData['frequency'] != null)
                      _buildPopupDetailRow('Frequency',
                          '${medicineData['frequency']} times a day'),
                  ] else if (medicineData['selectionOption'] == 'Meal') ...[
                    _buildPopupDetailRow('Meal Timing',
                        medicineData['mealSelection']['beforeOrAfter']),
                    if (medicineData['mealSelection']['meals'] != null)
                      _buildPopupDetailRow(
                        'Meal',
                        _getMealInfo(medicineData['mealSelection']['meals']),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMealInfo(Map<String, dynamic> meals) {
    List<String> mealTypes = [];
    if (meals['breakfast'] == true) mealTypes.add('Breakfast');
    if (meals['lunch'] == true) mealTypes.add('Lunch');
    if (meals['dinner'] == true) mealTypes.add('Dinner');
    return mealTypes.isNotEmpty
        ? mealTypes.join(', ')
        : 'No specific meal selected';
  }
}
