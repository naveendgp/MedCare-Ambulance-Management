import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class BookAmbulance extends StatefulWidget {
  const BookAmbulance({super.key});

  @override
  State<BookAmbulance> createState() => _BookAmbulance();
}

class _BookAmbulance extends State<BookAmbulance> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pickupLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _additionalInfoController =
      TextEditingController();
  final MapController _mapController = MapController();

  String _selectedPriority = 'Non-Emergency';
  bool _isLoading = false;

  // Sample coordinates - you would get actual user location
  LatLng _currentLocation = LatLng(12.9716, 77.5946); // Example: Bangalore

  final List<String> _priorities = [
    'Emergency',
    'Non-Emergency',
    'Inter-Hospital Transfer',
  ];

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request location permission - use a more robust method
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable in settings.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update the LatLng for the map
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLocation;
      });

      // Move map to new location
      _mapController.move(_currentLocation, 15.0);

      // Try to get a human-readable address using geocoding
      String address = "";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Build a more structured address by combining components
          List<String> addressComponents = [];

          // Add detailed components in a specific order
          if (place.name != null &&
              place.name!.isNotEmpty &&
              place.name != place.street &&
              !place.name!.contains("7") &&
              !place.name!.contains("+")) {
            addressComponents.add(place.name!);
          }

          if (place.street != null && place.street!.isNotEmpty) {
            addressComponents.add(place.street!);
          }

          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressComponents.add(place.subLocality!);
          }

          if (place.locality != null && place.locality!.isNotEmpty) {
            addressComponents.add(place.locality!);
          }

          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty &&
              place.subAdministrativeArea != place.locality) {
            addressComponents.add(place.subAdministrativeArea!);
          }

          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressComponents.add(place.postalCode!);
          }

          // Join the non-empty parts
          address = addressComponents
              .where((component) => component.isNotEmpty)
              .join(', ');

          // If we still have no useful address
          if (address.isEmpty ||
              address.contains("+") ||
              (address.length < 5 && address.contains(RegExp(r'[0-9]')))) {
            // Try a different approach with administrative areas
            addressComponents = [];

            if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
              addressComponents.add(place.thoroughfare!);
            }

            if (place.subAdministrativeArea != null &&
                place.subAdministrativeArea!.isNotEmpty) {
              addressComponents.add(place.subAdministrativeArea!);
            }

            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressComponents.add(place.administrativeArea!);
            }

            if (place.country != null && place.country!.isNotEmpty) {
              addressComponents.add(place.country!);
            }

            address = addressComponents
                .where((component) => component.isNotEmpty)
                .join(', ');
          }
        }
      } catch (e) {
        print("Geocoding error: $e");
      }

      // If address is still empty or looks like a Plus Code, use a more friendly format with coordinates
      if (address.isEmpty ||
          address.contains("+") ||
          (address.length < 5 && address.contains(RegExp(r'[0-9]')))) {
        address =
            "Location (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})";
      }

      setState(() {
        _pickupLocationController.text = address;
        _isLoading = false;
      });
    } catch (e) {
      print("Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Show booking confirmation
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        _showConfirmationDialog();
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            // Using Dialog instead of AlertDialog for more control over the size
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Booking Confirmed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Content - wrapped in Expanded with SingleChildScrollView
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your ambulance has been booked successfully!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildConfirmationDetailItem(
                              icon: Icons.priority_high,
                              title: 'Priority',
                              value: _selectedPriority,
                              color: _getPriorityColor(_selectedPriority),
                            ),
                            _buildConfirmationDetailItem(
                              icon: Icons.location_on,
                              title: 'Pickup',
                              value: _pickupLocationController.text,
                            ),
                            _buildConfirmationDetailItem(
                              icon: Icons.navigation,
                              title: 'Destination',
                              value: _destinationController.text,
                            ),
                            Divider(height: 20),
                            _buildConfirmationDetailItem(
                              icon: Icons.access_time,
                              title: 'Estimated Arrival',
                              value:
                                  _selectedPriority == 'Emergency'
                                      ? '5-10 minutes'
                                      : '15-20 minutes',
                              color: Colors.blue.shade700,
                              isBold: true,
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade800,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Booking ID: #AMB${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Please keep this ID for reference',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade800
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                            ), // Reduce padding
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        SizedBox(width: 4), // Reduced spacing
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/trackAmbulance");
                            // Navigate to tracking screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ), // Reduced padding
                            minimumSize: Size.zero, // Allow smaller button
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_searching,
                                color: Colors.black,
                                size: 14,
                              ), // Smaller icon
                              SizedBox(width: 4), // Reduced spacing
                              Text(
                                'Track',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ), // Shorter text, smaller font
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildConfirmationDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey.shade700),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Ambulance',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue.shade800),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue.shade800),
                    SizedBox(height: 20),
                    Text(
                      'Processing your request...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  // Background design
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Main content
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header section
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade800,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_taxi,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Request an Ambulance',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Please provide the necessary details for your ambulance request',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Map section
                            _buildSectionTitle('Current Location', Icons.map),
                            SizedBox(height: 10),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentLocation,
                                    minZoom: 13.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.medcare.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          width: 40.0,
                                          height: 40.0,
                                          point: _currentLocation,
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),

                            // Priority selection
                            _buildSectionTitle(
                              'Priority Level',
                              Icons.warning_amber,
                            ),
                            SizedBox(height: 10),
                            Container(
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
                              child: Column(
                                children:
                                    _priorities.map((priority) {
                                      bool isSelected =
                                          _selectedPriority == priority;
                                      Color priorityColor = _getPriorityColor(
                                        priority,
                                      );

                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          unselectedWidgetColor:
                                              Colors.grey.shade400,
                                        ),
                                        child: RadioListTile<String>(
                                          title: Text(
                                            priority,
                                            style: TextStyle(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  isSelected
                                                      ? priorityColor
                                                      : Colors.grey.shade700,
                                            ),
                                          ),
                                          subtitle: Text(
                                            _getPriorityDescription(priority),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          secondary: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: priorityColor.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              priority == 'Emergency'
                                                  ? Icons.emergency
                                                  : priority ==
                                                      'Inter-Hospital Transfer'
                                                  ? Icons.local_hospital
                                                  : Icons.medical_services,
                                              color: priorityColor,
                                              size: 20,
                                            ),
                                          ),
                                          value: priority,
                                          groupValue: _selectedPriority,
                                          activeColor: priorityColor,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedPriority = value!;
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            SizedBox(height: 24),

                            // Location section
                            _buildSectionTitle(
                              'Pickup Location',
                              Icons.location_on,
                            ),
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3, // Give more space to the text field
                                  child: TextFormField(
                                    controller: _pickupLocationController,
                                    decoration: _buildInputDecoration(
                                      hintText: 'Enter pickup location',
                                      prefixIcon: Icons.location_on,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter pickup location';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 8), // Reduced padding
                                Expanded(
                                  flex: 1, // Give less space to the button
                                  child: ElevatedButton(
                                    onPressed: _getCurrentLocation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade800,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      minimumSize:
                                          Size.zero, // Allow button to be smaller
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.my_location,
                                      size: 18,
                                    ), // Icon only, no text
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Destination

                            // Additional information
                            _buildSectionTitle(
                              'Additional Information (Optional)',
                              Icons.note_add,
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _additionalInfoController,
                              decoration: _buildInputDecoration(
                                hintText:
                                    'Any special requirements or medical condition',
                                prefixIcon: Icons.info_outline,
                              ).copyWith(alignLabelWithHint: true),
                              maxLines: 3,
                            ),
                            SizedBox(height: 30),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _submitBooking,
                                icon: Icon(Icons.local_taxi),
                                label: Text(
                                  'Book Ambulance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Emergency note
                            if (_selectedPriority == 'Emergency')
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Emergency Request',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade800,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'For immediate life-threatening situations, please also call emergency services at 108.',
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade800),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefixIcon, color: Colors.blue.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }

  String _getPriorityDescription(String priority) {
    switch (priority) {
      case 'Emergency':
        return 'For life-threatening situations requiring immediate medical attention';
      case 'Non-Emergency':
        return 'For medical transport that is not time-critical';
      case 'Inter-Hospital Transfer':
        return 'For transferring patients between medical facilities';
      default:
        return '';
    }
  }
}
