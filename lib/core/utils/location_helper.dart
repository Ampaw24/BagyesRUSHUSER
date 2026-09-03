import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

/// Outcome status of a [LocationHelper.getCurrentLocation] attempt.
enum LocationStatus {
  success,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  error,
}

/// Result of [LocationHelper.getCurrentLocation].
///
/// [address] is always populated (falling back to a coordinate string when
/// geocoding is skipped or fails) so callers can render it directly.
class LocationResult {
  final LocationStatus status;
  final Position? position;
  final String address;

  const LocationResult({
    required this.status,
    required this.position,
    required this.address,
  });

  bool get isSuccess => status == LocationStatus.success;
}

/// A utility class for handling location and geocoding operations.
/// Follows DRY principles to share logic across User, Courier, and Vendor homes.
class LocationHelper {
  static const _unavailableAddress = 'Location unavailable';

  /// Populated once by [AppInitializer] at app launch — before login and
  /// well before any home screen mounts. Screens should read this first and
  /// only fall back to a fresh [getCurrentLocation] call if it's unset, so
  /// the GPS fix isn't re-acquired on every screen mount.
  static LocationResult? cachedResult;

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

  /// Fetches the current device position and, by default, reverse-geocodes
  /// it into a human-readable address.
  ///
  /// [accuracy] defaults to low — cheap, good enough for a passive header
  /// display. Pass [LocationAccuracy.high] for anything driving a delivery
  /// pin (checkout, parcel pickup/drop-off, the map picker's GPS button).
  ///
  /// [resolveAddress] can be set to false to skip the reverse-geocode call
  /// entirely when only coordinates are needed (e.g. a nearby-search query
  /// that discards the address) — `address` still comes back populated with
  /// the coordinate-string fallback.
  static Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.low,
    bool resolveAddress = true,
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLogger.w('[LocationHelper] Location services disabled');
      return const LocationResult(
        status: LocationStatus.serviceDisabled,
        position: null,
        address: _unavailableAddress,
      );
    }

    final permission = await ensurePermission();
    if (permission == LocationPermission.denied) {
      appLogger.w('[LocationHelper] Permission denied — skipping fetch');
      return const LocationResult(
        status: LocationStatus.permissionDenied,
        position: null,
        address: _unavailableAddress,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      appLogger.w('[LocationHelper] Permission denied forever — skipping fetch');
      return const LocationResult(
        status: LocationStatus.permissionDeniedForever,
        position: null,
        address: _unavailableAddress,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
    } on LocationServiceDisabledException catch (e, s) {
      appLogger.e(
        '[LocationHelper] Location services disabled mid-fetch',
        error: e,
        stackTrace: s,
      );
      return const LocationResult(
        status: LocationStatus.serviceDisabled,
        position: null,
        address: _unavailableAddress,
      );
    } on PermissionDeniedException catch (e, s) {
      appLogger.e(
        '[LocationHelper] Permission denied mid-fetch',
        error: e,
        stackTrace: s,
      );
      return const LocationResult(
        status: LocationStatus.permissionDenied,
        position: null,
        address: _unavailableAddress,
      );
    } on TimeoutException catch (e, s) {
      appLogger.e('[LocationHelper] GPS fetch timed out', error: e, stackTrace: s);
      return const LocationResult(
        status: LocationStatus.timeout,
        position: null,
        address: _unavailableAddress,
      );
    } catch (e, s) {
      appLogger.e('[LocationHelper] Failed to fetch position', error: e, stackTrace: s);
      return const LocationResult(
        status: LocationStatus.error,
        position: null,
        address: _unavailableAddress,
      );
    }

    // A (0,0) fix is a bogus/no-fix result on some devices — treat it the
    // same as a failed fetch rather than handing callers coordinates that
    // point at Null Island.
    if (position.latitude == 0.0 && position.longitude == 0.0) {
      appLogger.w('[LocationHelper] Discarding bogus (0,0) fix');
      return const LocationResult(
        status: LocationStatus.error,
        position: null,
        address: _unavailableAddress,
      );
    }

    appLogger.i(
      '[LocationHelper] Coordinates — '
      'lat: ${position.latitude}, lng: ${position.longitude}',
    );

    if (!resolveAddress) {
      return LocationResult(
        status: LocationStatus.success,
        position: position,
        address: LocationHelper.resolveAddress(
          null,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    }

    // Reverse-geocoding gets its own try/catch, separate from the GPS fetch
    // above: a geocode failure (network blip, no Play Services) shouldn't
    // discard an already-successful position — it should just fall back to
    // the coordinate-string address while keeping status = success.
    Placemark? place;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      place = placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e, s) {
      appLogger.e(
        '[LocationHelper] Reverse geocode failed',
        error: e,
        stackTrace: s,
      );
    }

    return LocationResult(
      status: LocationStatus.success,
      position: position,
      address: LocationHelper.resolveAddress(
        place,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  /// Formats a [Placemark] into a concise, human-readable address string.
  /// Falls back to a 5-decimal coordinate string when [p] is null or has no
  /// usable fields.
  static String resolveAddress(
    Placemark? p, {
    required double latitude,
    required double longitude,
  }) {
    if (p != null) {
      final street = _nonEmpty(p.street ?? p.thoroughfare);
      final sub = _nonEmpty(p.subLocality);
      final locality = _nonEmpty(p.locality);
      final subAdmin = _nonEmpty(p.subAdministrativeArea);
      final admin = _nonEmpty(p.administrativeArea);
      final country = _nonEmpty(p.country);

      final parts = <String>[];
      if (street != null) parts.add(street);
      if (sub != null) parts.add(sub);
      if (locality != null) parts.add(locality);
      if (parts.isEmpty && subAdmin != null) parts.add(subAdmin);
      if (parts.length < 2 && admin != null) parts.add(admin);
      if (country != null && !parts.contains(country)) parts.add(country);

      if (parts.isNotEmpty) return parts.join(', ');
    }
    return _coordFallback(latitude, longitude);
  }

  static String? _nonEmpty(String? s) =>
      (s != null && s.trim().isNotEmpty) ? s.trim() : null;

  static String _coordFallback(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// Returns the OS's cached last-known position, if any, without waiting
  /// for a fresh GPS fix — resolves instantly, or `null` if the OS has never
  /// obtained a fix for this app. Use to paint a location optimistically
  /// while [getCurrentLocation] acquires a fresh fix in the background —
  /// a fresh fix's [getCurrentLocation] `timeLimit` can otherwise elapse
  /// before the OS reports a position on a cold GPS start.
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e, s) {
      appLogger.e(
        '[LocationHelper] getLastKnownPosition failed',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Opens the OS app-settings screen — use for a permanently-denied
  /// permission. Returns whether the settings screen was actually opened.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the OS location-services settings screen — use for disabled GPS.
  /// Returns whether the settings screen was actually opened.
  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
