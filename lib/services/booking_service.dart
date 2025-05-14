import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:med_care/config/supabase_config.dart';
import 'package:med_care/models/booking_model.dart';

class BookingService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Booking methods
  static Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final response =
          await client
              .from('bookings')
              .insert(booking.toJson())
              .select()
              .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  static Future<List<BookingModel>> getBookingsByPhone(String phone) async {
    try {
      final response = await client
          .from('bookings')
          .select()
          .eq('user_phone', phone)
          .order('created_at', ascending: false);

      return (response as List)
          .map((booking) => BookingModel.fromJson(booking))
          .toList();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response =
          await client.from('bookings').select().eq('id', bookingId).single();

      return BookingModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting booking: $e');
      return null;
    }
  }
}
