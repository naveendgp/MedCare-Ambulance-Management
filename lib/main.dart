import 'package:flutter/material.dart';
import 'package:med_care/Screens/book_ambulance.dart';
import 'package:med_care/Screens/home.dart';
import 'package:med_care/Screens/profile.dart';
import 'package:med_care/Screens/register.dart';
import 'package:med_care/Screens/track_ambulance.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Register(), // Start with Register screen
      routes: {
        '/home': (context) => Home(),
        '/register': (context) => Register(),
        '/bookAmbulance': (context) => BookAmbulance(),
        '/trackAmbulance': (context) => TrackAmbulance(),
        "/bookingHistory": (context) => RecentBookingsScreen(),
        "/profile" : (context) => ProfileScreen()
      },
    );
  }
}
