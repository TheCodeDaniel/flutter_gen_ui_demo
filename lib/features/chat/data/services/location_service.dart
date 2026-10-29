import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Finds the user's city, so the AI can look up prices where they live.
class LocationService {
  /// Returns something like "Ikeja, Lagos, Nigeria",
  /// or null if we can't get it (the AI will then ask the user instead).
  static Future<String?> getUserCity() async {
    try {
      // 1. Ask for permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      // 2. Get a rough position (city level is enough), the last known one is fastest
      final Position position =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
          );

      // 3. Turn the coordinates into a readable place name
      final List<Placemark> places = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      final Placemark place = places.first;

      return [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((part) => part != null && part.isNotEmpty).join(', ');
    } catch (error) {
      debugPrint("Location unavailable: $error");
      return null;
    }
  }
}
