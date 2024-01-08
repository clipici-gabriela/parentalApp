import 'package:location/location.dart';

class LocationService {
  final Location location = Location();

  Stream<LocationData>? get locationStream => location.onLocationChanged;

  Future<LocationData> getCurrentLocation() async {
    return await location.getLocation();
  }

  Future<bool> serviceEnabled() async {
    return await location.serviceEnabled();
  }

  Future<bool> requestService() async {
    return await location.requestService();
  }

  Future<PermissionStatus> permissionGranted() async {
    return await location.hasPermission();
  }

  Future<PermissionStatus> requestPermission() async {
    return await location.requestPermission();
  }

}
