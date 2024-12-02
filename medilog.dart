import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MedicineLogPage extends StatefulWidget {
  const MedicineLogPage({Key? key}) : super(key: key);

  @override
  _MedicineLogPageState createState() => _MedicineLogPageState();
}

class _MedicineLogPageState extends State<MedicineLogPage> {
  List<Map<String, dynamic>> _medicineLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicineLogs();
  }

  Future<void> _fetchMedicineLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medicine_logs')
            .orderBy('loggedAt', descending: true)
            .get();

        setState(() {
          _medicineLogs = querySnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicine logs: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Logs', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            : _medicineLogs.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'No medicine logs yet!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _medicineLogs.length,
                    itemBuilder: (context, index) {
                      final log = _medicineLogs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16.h),
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          title: Text(
                            log['medicineName'] ?? 'Unknown Medicine',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logged at: ${log['loggedAt'].toDate()}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              if (log['note'] != null)
                                Text(
                                  'Note: ${log['note']}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}