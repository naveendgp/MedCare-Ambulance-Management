import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:med_care/Screens/book_ambulance.dart';
import 'package:med_care/Screens/driver_dashboard.dart';
import 'package:med_care/Screens/driver_login.dart';
import 'package:med_care/Screens/home.dart';
import 'package:med_care/Screens/profile.dart';
import 'package:med_care/Screens/register.dart';
import 'package:med_care/Screens/track_ambulance.dart';
import 'package:med_care/services/booking_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await BookingService.initialize();

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
        '/bookingHistory':
            (context) => RecentBookingsScreen(), // Make sure this class exists
        '/profile': (context) => ProfileScreen(), // Make sure this class exists
        '/driverLogin': (context) => DriverLogin(),
        '/driverDashboard': (context) => DriverDashboard(),
      },
    );
  }
}
