import 'package:flutter/material.dart';

// IMPORTANT: Ensure this path matches your actual service file location!
import '../services/duffel_service.dart'; 

class FlightResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final String date;

  const FlightResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
  });

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _flights = [];

  @override
  void initState() {
    super.initState();
    _fetchFlightsFromDuffel();
  }

  Future<void> _fetchFlightsFromDuffel() async {
    try {
      // 1. LIVE GRID CONNECTION: Fetching real pricing and data from Duffel
      // NOTE: Using positional arguments exactly as your service expects them!
      final results = await DuffelService.searchFlights(
        widget.origin,
        widget.destination,
        widget.date,
      );
      
      setState(() {
        _flights = results;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          '${widget.origin} to ${widget.destination}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // State 1: Loading
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Querying live global aviation grid...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // State 2: Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // State 3: No Flights
    if (_flights.isEmpty) {
      return const Center(
        child: Text(
          'No flights found for this route on this date.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    // State 4: Success - Render the Live Flights
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flights.length,
      itemBuilder: (context, index) {
        final flight = _flights[index];
        
        // --- DATA MAPPING: Extracting live Duffel nested JSON ---
        // 1. Airline Name
        final airlineName = flight['owner']?['name'] ?? 'Unknown Airline';
        
        // 2. Price
        final price = flight['total_amount'] ?? '0.00';
        
        // 3. Departure Time (Safely digging into Duffel's 'slices')
        String departureTime = 'TBD';
        try {
          final slices = flight['slices'] as List?;
          if (slices != null && slices.isNotEmpty) {
            final segments = slices[0]['segments'] as List?;
            if (segments != null && segments.isNotEmpty) {
              final rawTime = segments[0]['departing_at']; 
              if (rawTime != null) {
                // Quick format from "2026-05-22T10:00:00" to a readable time
                final parsed = DateTime.parse(rawTime.toString());
                int hour = parsed.hour;
                final period = hour >= 12 ? 'PM' : 'AM';
                if (hour > 12) hour -= 12;
                if (hour == 0) hour = 12;
                final minute = parsed.minute.toString().padLeft(2, '0');
                departureTime = '$hour:$minute $period';
              }
            }
          }
        } catch (e) {
          // If the time parsing fails, it just defaults to 'TBD'
        }

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        airlineName, 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Departure: $departureTime', 
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$$price',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connecting to Stripe Checkout...'),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      },
                      child: const Text('Book', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}