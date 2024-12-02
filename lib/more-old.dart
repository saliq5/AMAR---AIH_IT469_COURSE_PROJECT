import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AMAR/edit_profile.dart'; // Import your edit profile page
import 'package:AMAR/profile.dart'; // Import the ProfilePage
// import 'package:AMAR/home.dart'; // Import your HomePage
import 'package:AMAR/main.dart';

class MorePage extends StatefulWidget {
  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('More'),
      ),
      body: ListView(
        children: [
          // View Profile Option
          ListTile(
            leading: Icon(Icons.person),
            title: Text('View Profile'),
            onTap: () {
              // Navigate to the Profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          Divider(),

          // Edit Profile Option
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            onTap: () {
              // Navigate to the Edit Profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileApp()),
              );
            },
          ),
          Divider(),

          // Change Theme Option
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Change Theme'),
            onTap: () {
              // Display a SnackBar as a placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Change Theme placeholder')),
              );
            },
          ),
          Divider(),

          // Privacy Policy Option
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Privacy Policy placeholder')),
              );
            },
          ),
          Divider(),

          // Terms of Service Option
          ListTile(
            leading: Icon(Icons.article),
            title: Text('Terms of Service'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Terms of Service placeholder')),
              );
            },
          ),
          Divider(),

          // About Section Option
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('About placeholder')),
              );
            },
          ),
          Divider(),

          // Logout Option
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut(); // Ensure this completes
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage()), // Replace with HomePage
              );
            },
          ),
        ],
      ),
    );
  }
}
