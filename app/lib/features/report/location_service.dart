import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Why the GPS position could not be read.
enum LocationIssue {
  /// Location (GPS) is turned off in the phone.
  serviceDisabled,

  /// The user said no; we can ask again.
  denied,

  /// The user said «don't ask again»: only the app settings can fix it.
  deniedForever,

  /// No fix in time (e.g. indoors).
  unavailable,
}

class LocationResult {
  const LocationResult.ok(double this.lat, double this.lng) : issue = null;

  const LocationResult.failed(LocationIssue this.issue)
      : lat = null,
        lng = null;

  final double? lat;
  final double? lng;
  final LocationIssue? issue;

  bool get isOk => issue == null;
}

/// Reads the GPS position, asking for the permission when needed (geolocator).
class LocationService {
  Future<LocationResult> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failed(LocationIssue.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failed(LocationIssue.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failed(LocationIssue.deniedForever);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.ok(position.latitude, position.longitude);
    } catch (_) {
      return const LocationResult.failed(LocationIssue.unavailable);
    }
  }

  /// Opens the phone settings that fix [issue].
  Future<void> openSettings(LocationIssue issue) async {
    if (issue == LocationIssue.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
