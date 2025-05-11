import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'MedCare',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, color: Colors.blue.shade800, size: 20),
            ),
            onPressed: () {
              Navigator.pushNamed(context, "/profile");
              // Navigate to profile or settings
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
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
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Emergency Services',
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
                      'Need urgent medical assistance?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle emergency call
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade800,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CALL EMERGENCY (108)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Services section title
              Text(
                'Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 15),

              // Main features in cards
              Row(
                children: [
                  // Book Ambulance Card
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Book Ambulance',
                      icon: Icons.add_road,
                      color: Colors.green.shade700,
                      onTap: () {
                        Navigator.pushNamed(context, "/bookAmbulance");
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Track Ambulance Card
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Track Ambulance',
                      icon: Icons.location_on,
                      color: Colors.orange.shade700,
                      onTap: () {
                        // Navigate to track ambulance screen
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  // Booking History Card
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Booking History',
                      icon: Icons.history,
                      color: Colors.purple.shade700,
                      onTap: () {
                        // Navigate to booking history screen
                        Navigator.pushNamed(context, "/bookingHistory");
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Medical Records Card
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Medical Records',
                      icon: Icons.medical_information,
                      color: Colors.blue.shade700,
                      onTap: () {
                        // Navigate to medical records screen
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 25),

              // Recent bookings section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/bookingHistory");
                    },
                    child: Text('View All'),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Recent booking list
              Container(
                height: 200, // Fixed height container
                child: FutureBuilder(
                  future: Future.wait([
                    Hive.openBox('bookings'),
                    Hive.openBox('users'),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final bookingBox = Hive.box('bookings');
                    final userBox = Hive.box('users');
                    final currentUserEmail = userBox.get('current_user_email');

                    // Filter bookings for current user
                    final allBookings = bookingBox.values.toList();
                    final bookings =
                        allBookings
                            .where(
                              (booking) =>
                                  booking is Map &&
                                  booking['userEmail'] == currentUserEmail,
                            )
                            .toList()
                            .reversed
                            .toList();

                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              'No recent bookings found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: bookings.length > 3 ? 3 : bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _getPriorityColor(
                                booking['priority'],
                              ).withOpacity(0.2),
                              child: Icon(
                                Icons.local_taxi,
                                color: _getPriorityColor(booking['priority']),
                              ),
                            ),
                            title: Text(
                              booking['pickup'] ?? 'Unknown Location',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('To: ${booking['destination'] ?? ''}'),
                                Text(
                                  'Priority: ${booking['priority'] ?? 'Standard'}',
                                  style: TextStyle(
                                    color: _getPriorityColor(
                                      booking['priority'],
                                    ),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  booking['timestamp'] != null
                                      ? _formatDateTime(booking['timestamp'])
                                      : 'Unknown time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Show booking details
                              Navigator.pushNamed(context, "/bookingHistory");
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 25),

              // Health tips section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Health Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Keep emergency contacts easily accessible. Create a list of emergency numbers including your doctor and nearest hospital.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade800,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'Tap to access',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Emergency':
        return Colors.red;
      case 'Inter-Hospital Transfer':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      // Today - show time only
      return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateTime.year == now.year) {
      // This year - show date and month
      return '${dateTime.day} ${_getMonthName(dateTime.month)}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Different year
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }
}
