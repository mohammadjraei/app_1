import 'package:geolocator/geolocator.dart';

class LocationService {
  // =========================================================
  // Permission
  // =========================================================

  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // =========================================================
  // Location Service / GPS
  // =========================================================

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // =========================================================
  // Get Current Location
  // =========================================================

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // =========================================================
  // Location Settings
  // =========================================================

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // =========================================================
  // App Settings
  // =========================================================

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
