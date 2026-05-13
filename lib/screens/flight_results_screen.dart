import 'package:flutter/material.dart';

// IMPORTANT: Uncomment and point this to your actual Duffel API file
// import '../services/duffel_service.dart'; 

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
  List<dynamic> _flights = []; // This will hold your Duffel flight offers

  @override
  void initState() {
    super.initState();
    _fetchFlightsFromDuffel();
  }

  Future<void> _fetchFlightsFromDuffel() async {
    try {
      // THE FIX: We pass widget.date directly! No more DateFormat parsing.
      // The AI is handing us a perfect "YYYY-MM-DD" string.
      
      /* --- UNCOMMENT THIS BLOCK TO ACTIVATE LIVE DUFFEL DATA ---
      final results = await DuffelService.searchFlights(
        origin: widget.origin,
        destination: widget.destination,
        departureDate: widget.date, 
      );
      
      setState(() {
        _flights = results;
        _isLoading = false;
      });
      --------------------------------------------------------- */

      // Temporary simulation for UI testing (Delete this when using live API above)
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoading = false;
        // Mock data to verify the UI renders correctly
        _flights = [{'airline': 'AeroSync Airways', 'price': '450.00', 'time': '10:00 AM'}]; 
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
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Theme Background
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Querying global aviation grid...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

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

    if (_flights.isEmpty) {
      return const Center(
        child: Text(
          'No flights found for this route on this date.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flights.length,
      itemBuilder: (context, index) {
        final flight = _flights[index];
        // Build your sleek flight cards here
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['airline'] ?? 'Airline', // Update keys based on Duffel JSON
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Departure: ${flight['time'] ?? 'TBD'}', 
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${flight['price'] ?? '0.00'}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Hook up your Stripe Checkout here!
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