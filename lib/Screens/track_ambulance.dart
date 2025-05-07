import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum BookingStatus { pending, accepted, inProgress, completed, cancelled }

class TrackAmbulance extends StatefulWidget {
  const TrackAmbulance({super.key});

  @override
  State<TrackAmbulance> createState() => _TrackAmbulance();
}

class _TrackAmbulance extends State<TrackAmbulance> {
  // In a real app, you would pass this data from the booking page or fetch from a server
  BookingStatus _status =
      BookingStatus.pending; // Change this to test different states
  final String _bookingId = "AMB123456";
  final String _pickupLocation = "123 Main Street, Bangalore";
  final String _destination = "City Hospital, MG Road";
  final String _priority = "Emergency";

  // Ambulance details (only available when request is accepted)
  final String _driverName = "Rajesh Kumar";
  final String _driverPhone = "+91 98765 43210";
  final String _ambulanceNumber = "KA 01 AB 1234";
  final String _vehicleType = "Advanced Life Support";

  // Sample coordinates for tracking
  LatLng _ambulanceLocation = LatLng(12.9716, 77.5946); // Starting point
  LatLng _destinationLocation = LatLng(12.9866, 77.6196); // Ending point
  final MapController _mapController = MapController();
  Timer? _timer;
  double _estimatedTimeMinutes = 15;
  double _distanceKm = 3.2;

  // For animation of ambulance movement
  int _moveCounter = 0;
  final int _totalMoves = 20;

  @override
  void initState() {
    super.initState();

    // Simulated status change: Pending -> Accepted after 5 seconds
    // In a real app, this would be a server notification
    if (_status == BookingStatus.pending) {
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _status = BookingStatus.accepted;
          });

          // Start ambulance movement simulation
          _startAmbulanceSimulation();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAmbulanceSimulation() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_moveCounter < _totalMoves) {
        setState(() {
          // Update ambulance location - moving it towards destination
          double newLat =
              _ambulanceLocation.latitude +
              (_destinationLocation.latitude - _ambulanceLocation.latitude) /
                  _totalMoves;
          double newLng =
              _ambulanceLocation.longitude +
              (_destinationLocation.longitude - _ambulanceLocation.longitude) /
                  _totalMoves;

          _ambulanceLocation = LatLng(newLat, newLng);
          _moveCounter++;

          // Update estimated time and distance
          _estimatedTimeMinutes = (_totalMoves - _moveCounter) * 0.75;
          _distanceKm = (_totalMoves - _moveCounter) * 0.16;
        });

        // Update map view
        _mapController.move(_ambulanceLocation, 15);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _status = BookingStatus.inProgress;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Ambulance',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue.shade800),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Emergency call functionality
              // You would implement actual call functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling emergency services...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: Icon(Icons.phone, color: Colors.red),
            label: Text('Emergency', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          _buildStatusBar(),

          // Main content based on status
          Expanded(
            child:
                _status == BookingStatus.pending
                    ? _buildPendingView()
                    : _buildTrackingView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_status) {
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = "Requesting Ambulance";
        statusIcon = Icons.hourglass_empty;
        break;
      case BookingStatus.accepted:
        statusColor = Colors.blue.shade700;
        statusText = "Ambulance Dispatched";
        statusIcon = Icons.medical_services;
        break;
      case BookingStatus.inProgress:
        statusColor = Colors.green;
        statusText = "Ambulance En Route";
        statusIcon = Icons.local_taxi;
        break;
      case BookingStatus.completed:
        statusColor = Colors.green.shade700;
        statusText = "Trip Completed";
        statusIcon = Icons.check_circle;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusText = "Request Cancelled";
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      color: statusColor.withOpacity(0.1),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_status == BookingStatus.pending)
                  Text(
                    'Finding the nearest available ambulance...',
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                if (_status == BookingStatus.accepted ||
                    _status == BookingStatus.inProgress)
                  Text(
                    'ETA: ${_estimatedTimeMinutes.toStringAsFixed(0)} minutes • ${_distanceKm.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (_status == BookingStatus.pending)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Info Card
            _buildBookingInfoCard(),
            SizedBox(height: 24),

            // First Aid Information
            Text(
              'While you wait: First Aid Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),

            // First Aid Tips List
            _buildFirstAidTip(
              title: 'For Bleeding',
              content:
                  'Apply direct pressure with a clean cloth or bandage to stop bleeding. If blood soaks through, add another layer without removing the first cloth.',
              icon: Icons.healing,
              color: Colors.red.shade700,
            ),
            _buildFirstAidTip(
              title: 'For Burns',
              content:
                  'Run cool (not cold) water over the burn for 10-15 minutes. Do not apply ice, butter, or ointments directly to the burn.',
              icon: Icons.whatshot,
              color: Colors.orange.shade700,
            ),
            _buildFirstAidTip(
              title: 'For Choking',
              content:
                  'Perform abdominal thrusts (Heimlich maneuver) if the person is conscious. Give 5 back blows if they cannot speak or cough.',
              icon: Icons.air,
              color: Colors.blue.shade700,
            ),
            _buildFirstAidTip(
              title: 'For Heart Attack',
              content:
                  'Have the person sit, rest, and try to keep calm. Loosen any tight clothing. If they have heart medication (like nitroglycerin), help them take it.',
              icon: Icons.favorite,
              color: Colors.pink.shade700,
            ),

            SizedBox(height: 20),

            // Disclaimer
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade700),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These tips are not a substitute for professional medical advice. Always call emergency services for serious medical situations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView() {
    return Column(
      children: [
        // Map for tracking
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ambulanceLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medcare.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_ambulanceLocation, _destinationLocation],
                      color: Colors.blue.shade700,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Ambulance marker
                    Marker(
                      width: 50,
                      height: 50,
                      point: _ambulanceLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_taxi,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                    // Destination marker
                    Marker(
                      width: 40,
                      height: 40,
                      point: _destinationLocation,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue.shade800,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Details panel
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking info
                _buildBookingInfoCard(),
                SizedBox(height: 16),

                // Ambulance & driver details
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver avatar
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue.shade800,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 16),

                          // Driver details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driverName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.8 (120+ trips)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _driverPhone,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Call button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                // Call driver functionality
                              },
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24),

                      // Ambulance details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ambulance',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _ambulanceNumber,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Type',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _vehicleType,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Cancel request functionality
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Cancel Request?'),
                                  content: Text(
                                    'Are you sure you want to cancel this ambulance request?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _status = BookingStatus.cancelled;
                                        });
                                        _timer?.cancel();
                                      },
                                      child: Text('Yes, Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                        icon: Icon(Icons.cancel_outlined),
                        label: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Chat with driver functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                        ),
                        icon: Icon(Icons.chat),
                        label: Text('Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking ID: $_bookingId',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _priority == "Emergency"
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _priority,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _priority == "Emergency"
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.blue.shade800),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'From: $_pickupLocation',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_searching,
                size: 16,
                color: Colors.red.shade800,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To: $_destination',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstAidTip({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
