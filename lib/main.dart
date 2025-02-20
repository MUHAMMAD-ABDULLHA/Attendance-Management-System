// import 'package:attendancemanagementsystem/utils/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'screens/login_screen.dart';
// import 'services/auth_service.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: FirebaseOptions(
//       apiKey: "AIzaSyAMBVX3ScIEIcZ-XunAja3nkhMYYIRK2pU",
//       authDomain: "attendancemanagementsyst-79f17.firebaseapp.com",
//       databaseURL: "https://attendancemanagementsyst-79f17-default-rtdb.firebaseio.com",
//       projectId: "attendancemanagementsyst-79f17",
//       storageBucket: "attendancemanagementsyst-79f17.firebasestorage.app",
//       messagingSenderId: "527096180881",
//       appId: "1:527096180881:web:f6460227070b982b74cf30",
//     ),
//   );
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//       ],
//       child: MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: AppConstants.appName,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: LoginScreen(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth_wrapper.dart'; // Import AuthWrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseOptions(
    apiKey: "AIzaSyAMBVX3ScIEIcZ-XunAja3nkhMYYIRK2pU",
    authDomain: "attendancemanagementsyst-79f17.firebaseapp.com",
    databaseURL: "https://attendancemanagementsyst-79f17-default-rtdb.firebaseio.com",
    projectId: "attendancemanagementsyst-79f17",
    storageBucket: "attendancemanagementsyst-79f17.firebasestorage.app",
    messagingSenderId: "527096180881",
    appId: "1:527096180881:web:f6460227070b982b74cf30",
  ),);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(), // Use AuthWrapper as the home screen
    );
  }
}