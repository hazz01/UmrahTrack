import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:umrahtrack/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationData? _currentPosition;
  StreamSubscription<LocationData>? _positionStreamSubscription;
  bool _isLocationServiceEnabled = false;
  bool _isTracking = false;
  String? _error;
  Location location = Location();
  
  // Getters
  LocationData? get currentPosition => _currentPosition;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isTracking => _isTracking;
  String? get error => _error;

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location services are enabled
      try {
        serviceEnabled = await location.serviceEnabled();
      } catch (e) {
        _error = 'Plugin location tidak terdaftar dengan benar. Error: $e';
        _isLocationServiceEnabled = false;
        notifyListeners();
        return false;
      }
      
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _error = 'Layanan lokasi tidak aktif. Silakan aktifkan di pengaturan.';
          _isLocationServiceEnabled = false;
          notifyListeners();
          return false;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _error = 'Izin lokasi ditolak';
          notifyListeners();
          return false;
        }
      }

      if (permissionGranted == PermissionStatus.deniedForever) {
        _error = 'Izin lokasi ditolak secara permanen. Silakan aktifkan dari pengaturan aplikasi.';
        notifyListeners();
        return false;
      }

      _isLocationServiceEnabled = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error checking location permission: $e';
      _isLocationServiceEnabled = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return;

      _currentPosition = await location.getLocation();
      
      await _saveLocationToFirebase();
      notifyListeners();
    } catch (e) {
      _error = 'Error mendapatkan lokasi: $e';
      notifyListeners();
    }
  }

  Future<void> startLocationTracking() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return;

      if (_isTracking) {
        stopLocationTracking();
      }

      // Configure location settings
      await location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: 10, // 10 meters
      );

      _positionStreamSubscription = location.onLocationChanged.listen(
        (LocationData locationData) {
          _currentPosition = locationData;
          _saveLocationToFirebase();
          notifyListeners();
        },
        onError: (e) {
          _error = 'Error tracking lokasi: $e';
          _isTracking = false;
          notifyListeners();
        },
      );      _isTracking = true;
      _error = null;
      
      // Save tracking status to Firebase
      await _saveTrackingStatusToFirebase(true);
      
      notifyListeners();
    } catch (e) {
      _error = 'Error memulai tracking: $e';
      _isTracking = false;
      notifyListeners();
    }
  }
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    
    // Save tracking status to Firebase
    _saveTrackingStatusToFirebase(false);
    
    notifyListeners();
  }

  Future<void> restartLocationTracking() async {
    stopLocationTracking();
    await Future.delayed(const Duration(seconds: 1));
    await startLocationTracking();
  }  Future<void> _saveLocationToFirebase() async {
    try {
      if (_currentPosition == null) {
        print('❌ LocationProvider: No current position to save');
        return;
      }

      print('🔄 LocationProvider: Saving location to Firebase');
      print('📍 Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      await LocationService.saveLocationToFirebase(
        latitude: _currentPosition!.latitude!,
        longitude: _currentPosition!.longitude!,
        accuracy: _currentPosition!.accuracy!,
        altitude: _currentPosition!.altitude ?? 0.0,
        speed: _currentPosition!.speed ?? 0.0,
      );

      print('✅ LocationProvider: Location saved successfully');
    } catch (e) {
      print('❌ LocationProvider: Error saving location to Firebase: $e');
      debugPrint('Error saving location to Firebase: $e');
    }
  }

  Future<void> _saveTrackingStatusToFirebase(bool isTracking) async {
    try {
      await LocationService.saveTrackingStatusToFirebase(isTracking);
    } catch (e) {
      debugPrint('Error saving tracking status to Firebase: $e');
    }
  }
  Future<void> openLocationSettings() async {
    try {
      await ph.Permission.location.request();
      if (await ph.Permission.location.isPermanentlyDenied) {
        await ph.openAppSettings();
      }
    } catch (e) {
      _error = 'Error membuka pengaturan: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
