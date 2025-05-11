import 'package:flutter/material.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboard();
}

class _DriverDashboard extends State<DriverDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text("Dashboard"));
  }
}
