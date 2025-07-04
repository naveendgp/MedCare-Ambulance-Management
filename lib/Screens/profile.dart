import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  bool isLoading = true;
  int totalBookings = 0;
  int emergencyBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userBox = await Hive.openBox('users');
    final bookingBox = await Hive.openBox('bookings');
    final currentUserEmail = userBox.get('current_user_email');

    if (currentUserEmail != null) {
      final userData = userBox.get(currentUserEmail);
      if (userData != null) {
        // Count bookings
        final bookings =
            bookingBox.values
                .where(
                  (booking) =>
                      booking is Map &&
                      booking['userEmail'] == currentUserEmail,
                )
                .toList();

        setState(() {
          userName = userData['name'] ?? 'User';
          userEmail = userData['email'] ?? '';
          emergencyBookings =
              bookings
                  .where((booking) => booking['priority'] == 'Emergency')
                  .length;
          isLoading = false;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.blue.shade800),
              )
              : CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildProfileBody()),
                ],
              ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.blue.shade800,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            // Edit profile functionality
          },
        ),
      ],
    );
  }

  Widget _buildProfileBody() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),

            // Quick Actions
            _buildSectionTitle('Quick Actions'),
            SizedBox(height: 16),
            _buildQuickActions(),

            SizedBox(height: 32),

            // Personal Information
            _buildSectionTitle('Personal Information'),
            SizedBox(height: 16),
            _buildInfoCard(),

            SizedBox(height: 32),

            // App Settings
            _buildSectionTitle('App Settings'),
            SizedBox(height: 16),
            _buildSettingsCard(),

            SizedBox(height: 32),

            // Help & Support
            _buildSectionTitle('Help & Support'),
            SizedBox(height: 16),
            _buildSupportCard(),

            SizedBox(height: 32),
            _buildLogoutButton(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionItem(
              Icons.medical_services,
              'Book\nAmbulance',
              Colors.blue,
            ),
            _buildActionItem(Icons.history, 'Booking\nHistory', Colors.purple),
            _buildActionItem(Icons.map, 'Track\nAmbulance', Colors.orange),
            _buildActionItem(Icons.notifications, 'Alerts', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileListTile(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Full Name',
            subtitle: userName,
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.email_outlined,
            iconColor: Colors.green,
            title: 'Email Address',
            subtitle: userEmail,
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.phone_outlined,
            iconColor: Colors.orange,
            title: 'Phone Number',
            subtitle: 'Not provided',
            onTap: () {
              // Add phone number
            },
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.location_on_outlined,
            iconColor: Colors.red,
            title: 'Home Address',
            subtitle: 'Not provided',
            onTap: () {
              // Add address
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileListTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.amber,
            title: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.blue.shade800,
            ),
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.dark_mode_outlined,
            iconColor: Colors.indigo,
            title: 'Dark Mode',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: Colors.blue.shade800,
            ),
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.language_outlined,
            iconColor: Colors.teal,
            title: 'Language',
            subtitle: 'English (US)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileListTile(
            icon: Icons.help_outline,
            iconColor: Colors.purple,
            title: 'Help Center',
            onTap: () {},
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.email_outlined,
            iconColor: Colors.cyan,
            title: 'Contact Support',
            onTap: () {},
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.blueGrey,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          Divider(height: 1, indent: 70),
          _buildProfileListTile(
            icon: Icons.description_outlined,
            iconColor: Colors.deepPurple,
            title: 'Terms of Service',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              )
              : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              )
              : null),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Show confirmation dialog
          final shouldLogout =
              await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Log Out'),
                      content: Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
              ) ??
              false;

          if (shouldLogout) {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue.shade800,
                    ),
                  ),
            );

            try {
              // Log out process - clear all user data
              final userBox = await Hive.openBox('users');
              await userBox.delete('current_user_email');

              // Optional: Clear any session or auth tokens if you have them
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.clear(); // Clear all preferences if needed

              // Remove loading indicator
              Navigator.pop(context);

              // Navigate to login screen and clear ALL previous routes
              // This ensures all activities are destroyed
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/register',
                (Route<dynamic> route) =>
                    false, // This predicate ensures ALL routes are removed
              );
            } catch (e) {
              // Remove loading indicator
              Navigator.pop(context);

              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to log out. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: Icon(Icons.logout),
        label: Text('Log Out'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
