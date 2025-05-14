class BookingModel {
  final String? id;
  final String userName;
  final String userPhone;
  final String pickupLocation;
  final String destinationLocation;
  final String ambulanceType;
  final String status;
  final DateTime createdAt;

  BookingModel({
    this.id,
    required this.userName,
    required this.userPhone,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.ambulanceType,
    this.status = 'pending',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userName: json['user_name'],
      userPhone: json['user_phone'],
      pickupLocation: json['pickup_location'],
      destinationLocation: json['destination_location'],
      ambulanceType: json['ambulance_type'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'user_phone': userPhone,
      'pickup_location': pickupLocation,
      'destination_location': destinationLocation,
      'ambulance_type': ambulanceType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
