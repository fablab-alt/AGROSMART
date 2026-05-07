import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Les permissions de localisation sont refusées');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Les permissions de localisation sont définitivement refusées, nous ne pouvons pas demander les permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      // On some devices/emulators, getting the position might hang if no fix is available.
      // We add a timeout and use specific settings.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Balanced/Medium accuracy
        timeLimit: const Duration(seconds: 10), // Prevent infinite wait
      );
    } catch (e) {
      if (e is TimeoutException) {
         return Future.error('Délai d\'attente de la localisation dépassé.');
      }
      return Future.error('Erreur lors de la récupération de la position: $e');
    }
  }
}

