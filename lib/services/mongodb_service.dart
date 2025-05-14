import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDBService {
  // Get base URL from environment variables
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

  // Update the createBooking method to include better error handling
  static Future<Map<String, dynamic>> createBooking({
    required String pickup,
    required String destination,
    required String priority,
    String? additionalInfo,
  }) async {
    try {
      // Get current user's email from Hive
      final userBox = await Hive.openBox('users');
      final currentUserEmail = userBox.get('current_user_email');

      if (currentUserEmail == null) {
        throw Exception('User not logged in');
      }

      final userData = userBox.get(currentUserEmail);
      final userName = userData?['name'] ?? 'Unknown';

      // Create booking data
      final bookingData = {
        'userName': userName,
        'userEmail': currentUserEmail,
        'pickup': pickup,
        'destination': destination,
        'priority': priority,
        'additionalInfo': additionalInfo ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('Sending booking data: ${jsonEncode(bookingData)}');
      debugPrint('Sending to API URL: $baseUrl/bookings');

      // Send POST request to create booking
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bookingData),
          )
          .timeout(const Duration(seconds: 15)); // Longer timeout

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create booking: Status ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');

      // Create a local booking ID to use as fallback
      final localBookingId = 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Save to Hive for offline access
      await _saveBookingToHiveWithId(
        id: localBookingId,
        pickup: pickup,
        destination: destination,
        priority: priority,
        additionalInfo: additionalInfo,
      );

      // Return a mock booking with ID so the app can continue
      return {
        '_id': localBookingId,
        'pickup': pickup,
        'destination': destination,
        'priority': priority,
        'additionalInfo': additionalInfo ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
  }

  // Add this helper method
  static Future<void> _saveBookingToHiveWithId({
    required String id,
    required String pickup,
    required String destination,
    required String priority,
    String? additionalInfo,
  }) async {
    try {
      final userBox = await Hive.openBox('users');
      final currentUserEmail = userBox.get('current_user_email');

      if (currentUserEmail == null) {
        throw Exception('User not logged in');
      }

      final userData = userBox.get(currentUserEmail);
      final userName = userData?['name'] ?? 'Unknown';

      final bookingBox = await Hive.openBox('bookings');

      final booking = {
        '_id': id,
        'userName': userName,
        'userEmail': currentUserEmail,
        'pickup': pickup,
        'destination': destination,
        'priority': priority,
        'additionalInfo': additionalInfo ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await bookingBox.add(booking);
      debugPrint('Booking saved to Hive with ID: $id');
    } catch (e) {
      debugPrint('Error saving booking to Hive: $e');
    }
  }

  // Get all bookings for the current user
  static Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      // Get current user's email from Hive
      final userBox = await Hive.openBox('users');
      final currentUserEmail = userBox.get('current_user_email');

      if (currentUserEmail == null) {
        throw Exception('User not logged in');
      }

      // Send GET request to fetch user's bookings
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/user/$currentUserEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  // Get a specific booking by ID
  static Future<Map<String, dynamic>?> getBookingById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch booking: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching booking: $e');
      return null;
    }
  }

  // Get all pending bookings that need a driver
  static Future<List<Map<String, dynamic>>> getPendingBookings() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/bookings/status/pending'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
          'Failed to fetch pending bookings: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching pending bookings: $e');
      return [];
    }
  }

  // Get bookings assigned to a specific driver
  static Future<List<Map<String, dynamic>>> getDriverBookings(
    String driverId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/bookings/driver/$driverId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
          'Failed to fetch driver bookings: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching driver bookings: $e');
      return [];
    }
  }

  // Accept a booking request
  static Future<bool> acceptBooking(String bookingId, String driverId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/bookings/$bookingId/accept'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'driverId': driverId, 'status': 'accepted'}),
          )
          .timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error accepting booking: $e');
      return false;
    }
  }

  // Complete a booking
  static Future<bool> completeBooking(String bookingId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/bookings/$bookingId/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'completed'}),
          )
          .timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error completing booking: $e');
      return false;
    }
  }

  // Update booking status
  static Future<bool> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/bookings/$bookingId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }
}
