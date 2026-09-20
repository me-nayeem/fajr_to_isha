import 'package:geolocator/geolocator.dart';

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});
}

enum LocationUnavailableReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}


sealed class LocationResult {
  const LocationResult();
}

class LocationAvailable extends LocationResult {
  final Coordinates coordinates;
  const LocationAvailable(this.coordinates);
}

class LocationUnavailable extends LocationResult {
  final LocationUnavailableReason reason;
  const LocationUnavailable(this.reason);
}

class LocationService {
  Future<LocationResult> getCurrentCoordinates({
    bool requestIfDenied = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationUnavailable(
        LocationUnavailableReason.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationUnavailable(
        LocationUnavailableReason.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationUnavailable(
        LocationUnavailableReason.permissionDeniedForever,
      );
    }

    try {
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      return LocationAvailable(
        Coordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const LocationUnavailable(LocationUnavailableReason.error);
    }
  }
}