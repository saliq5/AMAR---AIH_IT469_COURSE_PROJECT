import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EditProfileScreen();
  }
}

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();

  String gender = 'Male';
  TimeOfDay breakfastTime = TimeOfDay.now();
  TimeOfDay lunchTime = TimeOfDay.now();
  TimeOfDay dinnerTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          firstNameController.text = doc['firstName'] ?? '';
          lastNameController.text = doc['lastName'] ?? '';
          ageController.text = doc['age']?.toString() ?? '';
          addressController.text = doc['address'] ?? '';
          mobileNumberController.text = doc['mobileNumber'] ?? '';
          gender = doc['gender'] ?? 'Male';
          breakfastTime = _timeFromString(doc['breakfastTime']);
          lunchTime = _timeFromString(doc['lunchTime']);
          dinnerTime = _timeFromString(doc['dinnerTime']);
        });
      }
    }
  }

  TimeOfDay _timeFromString(String? time) {
    if (time == null || time.isEmpty) return TimeOfDay.now();
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(BuildContext context, String meal) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: meal == 'Breakfast' ? breakfastTime : meal == 'Lunch' ? lunchTime : dinnerTime,
    );
    if (picked != null) {
      setState(() {
        if (meal == 'Breakfast') {
          breakfastTime = picked;
        } else if (meal == 'Lunch') {
          lunchTime = picked;
        } else {
          dinnerTime = picked;
        }
      });
    }
  }

  void _submit() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        ageController.text.isEmpty ||
        addressController.text.isEmpty ||
        mobileNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      Map<String, dynamic> profileData = {
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'age': ageController.text.isNotEmpty ? int.parse(ageController.text) : null,
        'address': addressController.text,
        'mobileNumber': mobileNumberController.text,
        'gender': gender,
        'breakfastTime': '${breakfastTime.hour}:${breakfastTime.minute.toString().padLeft(2, '0')}',
        'lunchTime': '${lunchTime.hour}:${lunchTime.minute.toString().padLeft(2, '0')}',
        'dinnerTime': '${dinnerTime.hour}:${dinnerTime.minute.toString().padLeft(2, '0')}',
      };

      try {
        DocumentSnapshot doc = await userDoc.get();
        if (doc.exists) {
          await userDoc.update(profileData);
        } else {
          await userDoc.set(profileData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  Widget makeInput({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 5.h),
        TextField(
          keyboardType: keyboardType,
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.w),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget makeGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Gender",
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: gender,
              onChanged: (String? newValue) {
                setState(() {
                  gender = newValue!;
                });
              },
              items: <String>['Male', 'Female', 'Others']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(value, style: TextStyle(color: Colors.white)),
                  ),
                );
              }).toList(),
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, size: 20, color: Theme.of(context).colorScheme.primary),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: <Widget>[
                FadeInUp(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    "Edit Profile",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInUp(
                  duration: Duration(milliseconds: 400),
                  child: Text(
                    "Update your information",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInUp(duration: Duration(milliseconds: 500), child: makeInput(label: "First Name", controller: firstNameController)),
                FadeInUp(duration: Duration(milliseconds: 600), child: makeInput(label: "Last Name", controller: lastNameController)),
                FadeInUp(duration: Duration(milliseconds: 700), child: makeInput(label: "Age", keyboardType: TextInputType.number, controller: ageController)),
                FadeInUp(duration: Duration(milliseconds: 800), child: makeGenderDropdown()),
                FadeInUp(duration: Duration(milliseconds: 900), child: makeInput(label: "Address", controller: addressController)),
                FadeInUp(duration: Duration(milliseconds: 1000), child: makeInput(label: "Mobile Number", keyboardType: TextInputType.phone, controller: mobileNumberController)),
                SizedBox(height: 20.h),
                FadeInUp(
                  duration: Duration(milliseconds: 1100),
                  child: ListTile(
                    title: Text('Breakfast Time: ${breakfastTime.format(context)}', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    onTap: () => _selectTime(context, 'Breakfast'),
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 1200),
                  child: ListTile(
                    title: Text('Lunch Time: ${lunchTime.format(context)}', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    onTap: () => _selectTime(context, 'Lunch'),
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 1300),
                  child: ListTile(
                    title: Text('Dinner Time: ${dinnerTime.format(context)}', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    onTap: () => _selectTime(context, 'Dinner'),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInUp(
                  duration: Duration(milliseconds: 1400),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}