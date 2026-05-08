import 'package:flutter/material.dart';

class BoardingPassScreen extends StatelessWidget {
  final dynamic flight;

  const BoardingPassScreen({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    final airline = flight['airline'] ?? 'Unknown Airline';
    final origin = flight['origin'] ?? 'ORG';
    final destination = flight['destination'] ?? 'DST';
    final departureDate = flight['departure_date'] ?? 'N/A';
    // Generate a fake flight number based on the ID for realism
    final flightNumber = 'FL-${flight['id'].toString().substring(0, 4).toUpperCase()}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background
      appBar: AppBar(
        title: const Text('Your Boarding Pass'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- TOP TICKET SECTION ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(airline, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
                
                // --- FLIGHT DETAILS SECTION ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(origin, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const Text('Origin', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Icon(Icons.flight_takeoff, size: 40, color: Colors.blueAccent),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(destination, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const Text('Destination', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailColumn('DATE', departureDate),
                          _buildDetailColumn('FLIGHT', flightNumber),
                          _buildDetailColumn('GATE', 'TBD'),
                          _buildDetailColumn('SEAT', '14A'),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- DASHED DIVIDER ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Colors.grey, thickness: 2), 
                ),

                // --- BOTTOM BARCODE SECTION ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 120, color: Colors.black87),
                      const SizedBox(height: 12),
                      Text('Passenger: ${flight['passenger_name'] ?? 'Guest'}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for small text columns
  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
