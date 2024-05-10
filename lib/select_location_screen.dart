import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;
  SelectLocationScreen({this.initialLocation});

  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late MapController mapController;
  LatLng? _selectedPosition;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _selectedPosition = widget.initialLocation;
    if (_selectedPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(_selectedPosition!, 15.0);
      });
    } else {
      getCurrentLocation();
    }
  }

  void getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _showErrorDialog('Usługi lokalizacyjne wyłączone', 'Prosze włączyć usługi lokalizacyjne.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return _showErrorDialog('Dostęp do lokalizacji niedostępny', 'Nadaj uprawnienia do lokalizacji.');
      }
    }

    if (permission == LocationPermission.denied) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedPosition = LatLng(position.latitude, position.longitude);
      mapController.move(_selectedPosition!, 15.0);
    });
  }

  void _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    List<Location> locations = await locationFromAddress(_searchController.text);
    if (locations.isNotEmpty) {
      LatLng newLocation = LatLng(locations.first.latitude, locations.first.longitude);
      setState(() {
        _selectedPosition = newLocation;
        mapController.move(_selectedPosition!, 15.0);
      });
    } else {
      _showErrorDialog('Lokalizacja nieznaleziona', 'Nie znaleziono podanego adresu.');
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Szukaj lokalizacji',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchLocation,
          ),
        ),
        onSubmitted: (value) => _searchLocation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wybierz lokalizacje'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _selectedPosition == null ? null : () => Navigator.pop(context, _selectedPosition),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _selectedPosition ?? LatLng(0.0, 0.0),
                initialZoom: 15.0,
                onTap: (_, latLng) {
                  setState(() {
                    _selectedPosition = latLng;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedPosition != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _selectedPosition!,
                        child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: getCurrentLocation,
              child: Text('Pobierz aktualną lokalizację'),
            ),
          ),
        ],
      ),
    );
  }
}
