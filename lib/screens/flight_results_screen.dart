import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'flight_details_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final String departureDate;

  const FlightResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureDate,
  });

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate a network call to an airline API
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // Generate a list of mock flights based on the user's search
  List<Map<String, dynamic>> _generateMockFlights() {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Guest';
    return [
      {
        'id': '101',
        'airline': 'Duffel Airways',
        'origin': widget.origin.toUpperCase(),
        'destination': widget.destination.toUpperCase(),
        'price': 142.50,
        'currency': 'USD',
        'departure_date': widget.departureDate,
        'passenger_name': userEmail,
        'time': '08:00 AM - 10:30 AM',
        'duration': '2h 30m',
      },
      {
        'id': '102',
        'airline': 'SkyHigh Express',
        'origin': widget.origin.toUpperCase(),
        'destination': widget.destination.toUpperCase(),
        'price': 185.00,
        'currency': 'USD',
        'departure_date': widget.departureDate,
        'passenger_name': userEmail,
        'time': '11:15 AM - 01:45 PM',
        'duration': '2h 30m',
      },
      {
        'id': '103',
        'airline': 'Global Air',
        'origin': widget.origin.toUpperCase(),
        'destination': widget.destination.toUpperCase(),
        'price': 210.00,
        'currency': 'USD',
        'departure_date': widget.departureDate,
        'passenger_name': userEmail,
        'time': '04:45 PM - 07:20 PM',
        'duration': '2h 35m',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('${widget.origin.toUpperCase()} to ${widget.destination.toUpperCase()}'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text('Querying live inventory...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _generateMockFlights().length,
              itemBuilder: (context, index) {
                final flight = _generateMockFlights()[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlightDetailsScreen(flight: flight),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.airlines, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Text(flight['airline'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Text('\$${flight['price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          const Divider(color: Colors.grey, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(flight['time'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Non-stop', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(flight['duration'], style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(flight['departure_date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}