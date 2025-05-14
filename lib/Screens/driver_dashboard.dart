import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:med_care/services/mongodb_service.dart';
import 'dart:async';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String driverName = '';
  String driverId = '';
  String vehicleNumber = '';
  bool isOnDuty = false;
  List<Map<String, dynamic>> activeRequests = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    final driverBox = await Hive.openBox('drivers');
    final currentDriverId = driverBox.get('current_driver_id');

    if (currentDriverId != null) {
      final driverData = driverBox.get(currentDriverId);
      if (driverData != null) {
        setState(() {
          driverId = currentDriverId;
          driverName = driverData['name'] ?? 'Unknown Driver';
          vehicleNumber = driverData['vehicle'] ?? 'Unknown Vehicle';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Start periodic refresh when going on duty
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (isOnDuty) {
        _fetchBookingRequests();
      }
    });
  }

  // Stop periodic refresh when going off duty
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Fetch booking requests from MongoDB
  Future<void> _fetchBookingRequests() async {
    if (!isOnDuty) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get pending booking requests
      final pendingRequests = await MongoDBService.getPendingBookings();

      // If the driver has accepted any bookings, get those too
      final acceptedRequests = await MongoDBService.getDriverBookings(driverId);

      // Combine both lists, with accepted requests first
      setState(() {
        activeRequests = [...acceptedRequests, ...pendingRequests];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load booking requests: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Accept a booking request
  Future<void> _acceptRequest(String bookingId, int index) async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await MongoDBService.acceptBooking(bookingId, driverId);

      if (success) {
        await _fetchBookingRequests(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to accept booking');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Complete a booking
  Future<void> _completeRequest(String bookingId, int index) async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await MongoDBService.completeBooking(bookingId);

      if (success) {
        await _fetchBookingRequests(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request completed successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        throw Exception('Failed to complete booking');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleDutyStatus() {
    setState(() {
      isOnDuty = !isOnDuty;
    });

    if (isOnDuty) {
      _fetchBookingRequests();
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
      setState(() {
        activeRequests = [];
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnDuty ? 'You are now on duty' : 'You are now off duty',
        ),
        backgroundColor: isOnDuty ? Colors.green : Colors.grey,
      ),
    );
  }

  void _signOut() async {
    final driverBox = await Hive.openBox('drivers');
    await driverBox.delete('current_driver_id');

    Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
  }

  // Manually refresh the list
  Future<void> _refresh() async {
    if (isOnDuty) {
      await _fetchBookingRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be on duty to view requests'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Driver status card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade500, Colors.green.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Ambulance: $vehicleNumber',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isOnDuty
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOnDuty ? Icons.check_circle : Icons.cancel,
                                color:
                                    isOnDuty
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                isOnDuty ? 'On Duty' : 'Off Duty',
                                style: TextStyle(
                                  color:
                                      isOnDuty
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _toggleDutyStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isOnDuty
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                        foregroundColor:
                            isOnDuty
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                      child: Text(isOnDuty ? 'Go Off Duty' : 'Go On Duty'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Active requests section
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (isOnDuty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${activeRequests.length} requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child:
                        isLoading
                            ? Center(child: CircularProgressIndicator())
                            : !isOnDuty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.car_crash_outlined,
                                    size: 70,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Go on duty to view booking requests',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _toggleDutyStatus,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade500,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Go On Duty'),
                                  ),
                                ],
                              ),
                            )
                            : activeRequests.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 70,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'No active requests',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  TextButton.icon(
                                    onPressed: _refresh,
                                    icon: Icon(Icons.refresh),
                                    label: Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: activeRequests.length,
                              itemBuilder: (context, index) {
                                final request = activeRequests[index];
                                final requestId = request['_id'] ?? '';
                                final String status =
                                    request['status'] ?? 'pending';
                                final isPending = status == 'pending';
                                final isAccepted = status == 'accepted';
                                final isAssigned =
                                    request['driverId'] == driverId;

                                // Convert pickup and destination from API format
                                final String pickup =
                                    request['pickup'] ?? 'Unknown location';
                                final String destination =
                                    request['destination'] ??
                                    'Unknown destination';
                                final String priority =
                                    request['priority'] ?? 'Non-Emergency';
                                final String patientName =
                                    request['userName'] ?? 'Unknown';

                                // Format time from createdAt
                                final String time = _formatTime(
                                  request['createdAt'],
                                );

                                return Card(
                                  elevation: 3,
                                  margin: EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Request #${requestId.substring(0, Math.min(requestId.length, 8))}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isAccepted
                                                        ? Colors.blue.shade100
                                                        : isPending
                                                        ? Colors.amber.shade100
                                                        : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _formatStatus(status),
                                                style: TextStyle(
                                                  color:
                                                      isAccepted
                                                          ? Colors.blue.shade900
                                                          : isPending
                                                          ? Colors
                                                              .amber
                                                              .shade900
                                                          : Colors
                                                              .grey
                                                              .shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        // Priority indicator
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(
                                              priority,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _getPriorityColor(
                                                priority,
                                              ).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            priority,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getPriorityColor(
                                                priority,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Patient: $patientName',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'From: $pickup',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'To: $destination',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 15),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Booked: $time',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (isPending && isOnDuty)
                                              ElevatedButton(
                                                onPressed:
                                                    () => _acceptRequest(
                                                      requestId,
                                                      index,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green.shade500,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text('Accept'),
                                              )
                                            else if (isAccepted && isAssigned)
                                              ElevatedButton(
                                                onPressed:
                                                    () => _completeRequest(
                                                      requestId,
                                                      index,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue.shade500,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text('Complete'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format priority colors
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Emergency':
        return Colors.red;
      case 'Inter-Hospital Transfer':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Helper method to format status
  String _formatStatus(String status) {
    return status
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  // Helper method to format time from timestamp
  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown time';

      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }

      // Format the time
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hrs ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
