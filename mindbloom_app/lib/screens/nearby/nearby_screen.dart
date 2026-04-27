import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../widgets/custom_card.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  int _selectedTab = 0; // 0: clinics, 1: bookstores
  final MapController _mapController = MapController();

  static const LatLng _initialPosition = LatLng(40.7128, -74.0060); // New York City center placeholder

  final List<Map<String, dynamic>> _mockClinics = [
    {'name': 'MindCare Wellness Center', 'address': '123 Health St, City', 'rating': 4.5, 'distance': '0.8 km', 'type': 'Psychiatrist', 'lat': 40.7150, 'lng': -74.0100},
    {'name': 'Serenity Mental Health Clinic', 'address': '456 Calm Ave, City', 'rating': 4.7, 'distance': '1.2 km', 'type': 'Psychologist', 'lat': 40.7200, 'lng': -73.9950},
    {'name': 'Peaceful Minds Therapy', 'address': '789 Peace Rd, City', 'rating': 4.3, 'distance': '2.1 km', 'type': 'Therapist', 'lat': 40.7100, 'lng': -74.0200},
    {'name': 'Harmony Counseling', 'address': '321 Harmony Ln, City', 'rating': 4.6, 'distance': '2.5 km', 'type': 'Counselor', 'lat': 40.7300, 'lng': -74.0000},
    {'name': 'Wellness Hub Clinic', 'address': '654 Wellness Blvd, City', 'rating': 4.4, 'distance': '3.0 km', 'type': 'General', 'lat': 40.7000, 'lng': -73.9900},
  ];

  final List<Map<String, dynamic>> _mockBookstores = [
    {'name': 'The Mindful Reader', 'address': '100 Book St, City', 'rating': 4.6, 'distance': '0.5 km', 'type': 'Self-help', 'lat': 40.7160, 'lng': -74.0110},
    {'name': 'Pages of Peace', 'address': '200 Read Ave, City', 'rating': 4.4, 'distance': '1.0 km', 'type': 'Wellness', 'lat': 40.7210, 'lng': -73.9960},
    {'name': 'Chapter One Books', 'address': '300 Story Rd, City', 'rating': 4.8, 'distance': '1.8 km', 'type': 'General', 'lat': 40.7110, 'lng': -74.0210},
    {'name': 'Leaf & Page', 'address': '400 Library Ln, City', 'rating': 4.5, 'distance': '2.3 km', 'type': 'Independent', 'lat': 40.7310, 'lng': -74.0010},
  ];

  List<Marker> _getMarkers(List<Map<String, dynamic>> places) {
    return places.map((place) {
      final isClinic = _selectedTab == 0;
      return Marker(
        point: LatLng(place['lat'] as double, place['lng'] as double),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_on,
          color: isClinic ? AppColors.primaryPurple : AppColors.softGreen,
          size: 40,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final places = _selectedTab == 0 ? _mockClinics : _mockBookstores;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby')),
      body: Column(
        children: [
          // Real Google Map
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialPosition,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mindbloom_app',
                  ),
                  MarkerLayer(
                    markers: _getMarkers(places),
                  ),
                ],
              ),
            ),
          ),

          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? AppColors.primaryPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTab == 0 ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_hospital_rounded,
                            color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text('Clinics',
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? AppColors.softGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTab == 1 ? AppColors.softGreen : Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded,
                            color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text('Bookstores',
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                final isClinic = _selectedTab == 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isClinic ? AppColors.primaryPurple : AppColors.softGreen).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isClinic ? Icons.medical_services_rounded : Icons.book_rounded,
                            color: isClinic ? AppColors.primaryPurple : AppColors.softGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(place['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(place['address'] as String, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: AppColors.warmAmber),
                                  const SizedBox(width: 2),
                                  Text('${place['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.directions_walk, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 2),
                                  Text(place['distance'] as String,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.calmBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(place['type'] as String,
                                      style: TextStyle(fontSize: 10, color: AppColors.calmBlue)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.directions_rounded, color: AppColors.calmBlue),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
