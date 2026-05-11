import 'package:flutter/material.dart';
import '../services/duffel_service.dart'; // Importing our new live API service!
import 'passenger_details_screen.dart';

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
  List<dynamic> _flights = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Trigger the API call the second the screen loads
    _fetchLiveFlights();
  }

  Future<void> _fetchLiveFlights() async {
    try {
      final flights = await DuffelService.searchFlights(
        widget.origin, 
        widget.destination, 
        widget.departureDate
      );
      
      if (mounted) {
        setState(() {
          _flights = flights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('${widget.origin} to ${widget.destination}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. The Loading State
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Querying global airlines...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 2. The Error State
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    // 3. The Empty State
    if (_flights.isEmpty) {
      return const Center(child: Text('No flights found for this route.', style: TextStyle(color: Colors.white)));
    }

    // 4. The Success State (Live Data)
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flights.length,
      itemBuilder: (context, index) {
        final flight = _flights[index];
        // Parsing the Duffel JSON structure
        final airline = flight['owner']['name'] ?? 'Unknown Airline';
        final price = flight['total_amount'];
        final currency = flight['total_currency'];
        final flightId = flight['id']; // We will use this ID for the checkout handoff next!

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.flight, color: Colors.white),
            ),
            title: Text(airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('ID: $flightId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$$price', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(currency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => PassengerDetailsScreen(
                     offerId: flightId,
                     airline: airline,
                     price: price.toString(),
                   ),
                 ),
               );
            },
          ), // <-- Closes the ListTile (Notice the parenthesis!)
        ); // <-- Closes the Card (Notice the parenthesis and semicolon!)
      },
    );
  }
}
