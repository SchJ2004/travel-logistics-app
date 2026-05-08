import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upgrades_screen.dart'; // <-- Changed to point to the new screen

class FlightDetailsScreen extends StatefulWidget {
  final dynamic flight;

  const FlightDetailsScreen({super.key, required this.flight});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  bool _isLoadingWeather = true;
  String _temperature = '--';
  String _weatherCondition = 'Fetching live radar...';
  IconData _weatherIcon = Icons.cloud;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final destination = widget.flight['destination'] ?? 'JFK';
    
    try {
      final url = Uri.parse('https://wttr.in/$destination?format=j1');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];

        final tempF = current['temp_F'];
        final condition = current['weatherDesc'][0]['value'];

        if (mounted) {
          setState(() {
            _temperature = '$tempF°F';
            _weatherCondition = condition;
            _isLoadingWeather = false;

            final lowerCondition = condition.toString().toLowerCase();
            if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
              _weatherIcon = Icons.wb_sunny;
            } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
              _weatherIcon = Icons.water_drop;
            } else if (lowerCondition.contains('snow')) {
              _weatherIcon = Icons.ac_unit;
            } else {
              _weatherIcon = Icons.cloud;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _weatherCondition = 'Weather unavailable at this airport';
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherCondition = 'Radar offline';
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final airline = widget.flight['airline'] ?? 'Unknown Airline';
    final price = widget.flight['price']?.toString() ?? 'N/A';
    final currency = widget.flight['currency'] ?? 'USD';
    final origin = widget.flight['origin'] ?? 'Origin';
    final destination = widget.flight['destination'] ?? 'Destination';
    final departureDate = widget.flight['departure_date'] ?? 'Selected Date';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Flight Details'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Card(
              color: const Color(0xFF1E293B),
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
                    const Divider(color: Colors.grey, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.airlines, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(airline, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Date: $departureDate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- AMENITIES ---
            const Text('Included in your fare', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.work_outline, color: Colors.green),
              title: Text('1 Personal Item', style: TextStyle(color: Colors.white)),
              subtitle: Text('Must fit under the seat in front of you', style: TextStyle(color: Colors.grey)),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 24),

            // --- DESTINATION WEATHER CARD ---
            const Text('Destination Outlook', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _isLoadingWeather 
                        ? const CircularProgressIndicator(color: Colors.blueAccent)
                        : Icon(_weatherIcon, size: 40, color: Colors.amberAccent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current weather at $destination', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_weatherCondition, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (!_isLoadingWeather)
                      Text(_temperature, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // --- PRICE & CONTINUE BUTTON ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base Price', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('$price $currency', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpgradesScreen(flight: widget.flight),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Select Seats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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