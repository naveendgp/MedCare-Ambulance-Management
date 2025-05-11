import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class RecentBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality could be added here
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([Hive.openBox('bookings'), Hive.openBox('users')]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: Colors.blue.shade800),
            );
          }

          final bookingBox = Hive.box('bookings');
          final userBox = Hive.box('users');
          final currentUserEmail = userBox.get('current_user_email');

          // Filter bookings for current user
          final bookings =
              bookingBox.values
                  .where(
                    (booking) =>
                        booking is Map &&
                        booking['userEmail'] == currentUserEmail,
                  )
                  .toList();

          // Group bookings by date
          Map<String, List> bookingsByDate = {};
          for (var booking in bookings) {
            if (booking['timestamp'] != null) {
              final date = DateTime.parse(booking['timestamp']);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);

              if (!bookingsByDate.containsKey(dateKey)) {
                bookingsByDate[dateKey] = [];
              }
              bookingsByDate[dateKey]!.add(booking);
            }
          }

          // Sort dates in descending order
          final sortedDates =
              bookingsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildBookingSummary(bookings),
                SizedBox(height: 24),
                ...sortedDates.map((dateKey) {
                  final dateBookings = bookingsByDate[dateKey]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateHeader(dateKey),
                      SizedBox(height: 12),
                      ...dateBookings
                          .map((booking) => _buildBookingCard(context, booking))
                          .toList(),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 80,
                color: Colors.blue.shade300,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Booking History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You haven\'t booked any ambulances yet. Book an ambulance to see your history here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Book Ambulance', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary(List bookings) {
    int emergencyCount =
        bookings.where((b) => b['priority'] == 'Emergency').length;
    int nonEmergencyCount =
        bookings.where((b) => b['priority'] == 'Non-Emergency').length;
    int transferCount =
        bookings
            .where((b) => b['priority'] == 'Inter-Hospital Transfer')
            .length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                count: emergencyCount,
                label: 'Emergency',
                color: Colors.red,
              ),
              _buildSummaryItem(
                count: nonEmergencyCount,
                label: 'Non-Emergency',
                color: Colors.green,
              ),
              _buildSummaryItem(
                count: transferCount,
                label: 'Transfer',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(Duration(days: 1));

    String dateText;
    if (DateFormat('yyyy-MM-dd').format(now) == dateKey) {
      dateText = 'Today';
    } else if (DateFormat('yyyy-MM-dd').format(yesterday) == dateKey) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('EEEE, MMMM d').format(date);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map booking) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient header with priority and timestamp
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getPriorityColor(booking['priority']).withOpacity(0.8),
                    _getPriorityColor(booking['priority']),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    booking['priority'] ?? 'Standard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatTime(booking['timestamp']),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue.shade800,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking['pickup'] ?? 'Unknown Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Additional info
                if ((booking['additionalInfo'] ?? '').isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking['additionalInfo'],
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // Divider
                Container(height: 1, color: Colors.grey.shade200),
                SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.replay,
                      label: 'Book Again',
                      color: Colors.blue.shade800,
                      onTap: () {
                        // Implement book again functionality
                      },
                    ),
                    SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.support_agent,
                      label: 'Support',
                      color: Colors.green,
                      onTap: () {
                        // Implement support functionality
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('h:mm a').format(dateTime);
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

  // Color _getPriorityColorLight(String? priority) {
  //   switch (priority) {
  //     case 'Emergency':
  //       return Colors.red.shade50;
  //     case 'Inter-Hospital Transfer':
  //       return Colors.orange.shade50;
  //     default:
  //       return Colors.green.shade50;
  //   }
  // }
}
