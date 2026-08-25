import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

/// A utility class for handling location and geocoding operations.
/// Follows DRY principles to share logic across User, Courier, and Vendor homes.
class LocationHelper {
  // Android/iOS only track one in-flight permission request at a time; a
  // second concurrent `requestPermission()` call never resolves instead of
  // erroring. Callers share this in-flight future so the launch-time
  // request (AppInitializer) and a screen's own request can't collide.
  static Future<LocationPermission>? _pendingPermissionRequest;

  /// Checks/requests the OS location permission. Call once at app launch
  /// (e.g. from [AppInitializer.initializeRemaining]) so the system prompt
  /// appears before login instead of when a home screen first mounts.
  static Future<LocationPermission> ensurePermission() {
    return _pendingPermissionRequest ??= _requestPermission().whenComplete(
      () => _pendingPermissionRequest = null,
    );
  }

  static Future<LocationPermission> _requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e, s) {
      appLogger.e(
        '[LocationHelper] Failed to request permission',
        error: e,
        stackTrace: s,
      );
      return LocationPermission.denied;
    }
  }

  /// Fetches the current location coordinates and resolves them into a human-readable address.
  ///
  /// Returns a Map containing:
  /// - 'address': The resolved address string
  /// - 'position': The [Position] object
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      final permission = await ensurePermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        appLogger.w(
          '[LocationHelper] Permission denied ($permission) — skipping fetch',
        );
        return {'address': 'Location unavailable', 'position': null};
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      appLogger.i(
        '[LocationHelper] Coordinates — '
        'lat: ${position.latitude}, lng: ${position.longitude}',
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final resolved = resolveAddress(place, position);

      return {'address': resolved, 'position': position};
    } catch (e, s) {
      appLogger.e(
        '[LocationHelper] Failed to fetch location',
        error: e,
        stackTrace: s,
      );
      return {'address': 'Location unavailable', 'position': null};
    }
  }

  /// Formats a [Placemark] into a concise address string.
  static String resolveAddress(Placemark? p, Position pos) {
    if (p != null) {
      final sub = p.subLocality?.isNotEmpty == true ? p.subLocality : null;
      final locality = p.locality?.isNotEmpty == true ? p.locality : null;
      final street = p.street?.isNotEmpty == true ? p.street : null;
      final area = p.administrativeArea?.isNotEmpty == true ? p.administrativeArea : null;
      final country = p.country?.isNotEmpty == true ? p.country : null;

      if (street != null && locality != null) return '$street, $locality';
      if (street != null) return street;
      if (sub != null && locality != null) return '$sub, $locality';
      if (sub != null) return sub;
      
      final parts = [locality, area ?? country].whereType<String>().toList();
      if (parts.isNotEmpty) return parts.join(', ');
      if (country != null) return country;
    }
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }
}
