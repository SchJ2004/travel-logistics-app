import 'package:flutter/material.dart';

class FlightDetailsScreen extends StatelessWidget {
  final dynamic flight;

  const FlightDetailsScreen({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    // Safely extract data whether it comes from the search API or the Supabase DB
    final airline = flight['airline'] ?? 'Unknown Airline';
    final price = flight['price']?.toString() ?? 'N/A';
    final currency = flight['currency'] ?? 'USD';
    final origin = flight['origin'] ?? 'Origin';
    final destination = flight['destination'] ?? 'Destination';
    
    // Fallback for departure date depending on where the data came from
    final departureDate = flight['departure_date'] ?? 'Selected Date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(origin, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            const Text('Departure', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Icon(Icons.flight_takeoff, size: 40, color: Colors.grey),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(destination, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            const Text('Arrival', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.airlines, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(airline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Date: $departureDate', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- AMENITIES & INFO ---
            const Text('Included in your fare', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.work_outline, color: Colors.green),
              title: Text('1 Personal Item'),
              subtitle: Text('Must fit under the seat in front of you'),
            ),
            const ListTile(
              leading: Icon(Icons.luggage, color: Colors.green),
              title: Text('1 Carry-on Bag'),
              subtitle: Text('Max dimensions: 22" x 14" x 9"'),
            ),
            const ListTile(
              leading: Icon(Icons.airline_seat_recline_normal, color: Colors.grey),
              title: Text('Standard Economy Seat'),
              subtitle: Text('Seat selection available at check-in'),
            ),
            
            const Spacer(),

            // --- PRICE & CHECKOUT BUTTON ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('$price $currency', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redirecting to checkout pipeline...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Book Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}