import 'package:flutter/material.dart';

class AirportGuideScreen extends StatefulWidget {
  const AirportGuideScreen({super.key});

  @override
  State<AirportGuideScreen> createState() => _AirportGuideScreenState();
}

class _AirportGuideScreenState extends State<AirportGuideScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Airport Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            Text('Lounges, Transport & Amenities', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NEW: THE SEARCH BAR ---
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search airports (e.g., MIA, LHR)',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // --- VIP LOUNGES ---
            const Text('VIP Lounges', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SkyHigh Premium Lounge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('85% Full', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Showers, Hot Buffet, Full Bar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code, color: Colors.white, size: 16),
                      label: const Text('Find Passes', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- GROUND TRANSPORT ---
            const Text('Ground Transport', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionCard(Icons.directions_car, 'Rental Cars'),
                const SizedBox(width: 12),
                _buildActionCard(Icons.directions_bus, 'Bus/Shuttle'),
                const SizedBox(width: 12),
                _buildActionCard(Icons.local_taxi, 'Rideshare'),
              ],
            ),
            const SizedBox(height: 24),

            // --- STAY & PLAY (Overflow Fixed!) ---
            const Text('Stay & Play', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionCard(Icons.bed, 'Hotels', subtitle: 'Find stays near'),
                const SizedBox(width: 12),
                _buildActionCard(Icons.restaurant, 'Dining', subtitle: 'Reserve a table'),
                const SizedBox(width: 12),
                _buildActionCard(Icons.directions_bike, 'Experiences', subtitle: 'Tours & Rentals'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep the rows clean and prevent overflow
  Widget _buildActionCard(IconData icon, String title, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]
          ],
        ),
      ),
    );
  }
}