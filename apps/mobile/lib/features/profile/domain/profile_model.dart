/// Profile Domain Model
library;

import 'package:flutter/foundation.dart';

@immutable
class BirthProfile {
  const BirthProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String dateOfBirth; // YYYY-MM-DD
  final String timeOfBirth; // HH:MM:SS
  final String placeName;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isPrimary;

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    return BirthProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      timeOfBirth: json['time_of_birth'] as String,
      placeName: json['place_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date_of_birth': dateOfBirth,
        'time_of_birth': timeOfBirth,
        'place_name': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'is_primary': isPrimary,
      };

  @override
  String toString() => 'BirthProfile($name, $placeName)';
}
