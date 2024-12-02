import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          "AMAR",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Image.asset(
              'assets/images/amar_logo.png',
              height: 30.h,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface],
          ),
        ),
        child: user != null
            ? FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading profile.', style: TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('No profile found.', style: TextStyle(color: Colors.white)));
                  }

                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileField(context, icon: Icons.email, title: 'Email', value: user.email!),
                          _buildProfileField(context, icon: Icons.person, title: 'First Name', value: userData['firstName'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.person, title: 'Last Name', value: userData['lastName'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.calendar_today, title: 'Age', value: userData['age']?.toString() ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.location_on, title: 'Address', value: userData['address'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.phone, title: 'Mobile Number', value: userData['mobileNumber'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.transgender, title: 'Gender', value: userData['gender'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.access_time, title: 'Breakfast Time', value: userData['breakfastTime'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.access_time, title: 'Lunch Time', value: userData['lunchTime'] ?? 'N/A'),
                          _buildProfileField(context, icon: Icons.access_time, title: 'Dinner Time', value: userData['dinnerTime'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  'No user is logged in.',
                  style: TextStyle(fontSize: 24.sp, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileField(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Icon(
                icon,
                size: 30.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}