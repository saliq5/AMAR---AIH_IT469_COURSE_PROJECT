import 'package:AMAR/notification_helper.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:AMAR/login.dart';
import 'package:AMAR/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'todayInfo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationHelper.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final notificationService = NotificationService();
  await notificationService.scheduleAllMedicationNotifications();
  
  runApp(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: NotificationHelper.navigatorKey, // This is important
          routes: {
            '/editProfile': (context) => TodayInfoPage(date: DateTime.now()),
          },
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF2AC9CD),
              surface: Color(0xFF1E1E1E),
            ),
            textTheme: TextTheme(
              displayLarge:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Colors.grey[300]),
              labelLarge: TextStyle(color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF2AC9CD),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF2AC9CD),
                side: BorderSide(color: Color(0xFF2AC9CD)),
              ),
            ),
          ),
          home: AuthWrapper(notificationService: notificationService),
        );
      },
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  final NotificationService notificationService;

  const AuthWrapper({Key? key, required this.notificationService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start listening for medication changes as soon as the app starts
    notificationService.listenToMedicationChanges();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return Home(); // Navigate to Home if user is logged in
        }
        return HomePage(); // Navigate to Login/Signup if user is not logged in
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 50.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FadeInDown(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    "Welcome to",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ),
                FadeInDown(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    "AMAR",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 40.sp,
                        ),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInDown(
                  duration: Duration(milliseconds: 1400),
                  child: Text(
                    "AI-powered Medicine Administration Reminder",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16.sp,
                        ),
                  ),
                ),
                Expanded(
                  child: FadeInUp(
                    duration: Duration(milliseconds: 1600),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/amar_logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 1800),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    child: Text(
                      "Login",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInUp(
                  duration: Duration(milliseconds: 2000),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    child: Text(
                      "Sign up",
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
