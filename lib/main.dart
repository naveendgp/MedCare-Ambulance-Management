import 'package:flutter/material.dart';
import 'package:med_care/Screens/book_ambulance.dart';
import 'package:med_care/Screens/home.dart';
import 'package:med_care/Screens/register.dart';
import 'package:med_care/Screens/track_ambulance.dart';

void main() {
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Register()),
      routes: {
        "/home": (context) => Home(),
        "/bookAmbulance": (context) => BookAmbulance(),
        "/trackAmbulance":(context) => TrackAmbulance()
      },
    );
  }
}
