import 'package:flutter/material.dart';
import '../services/duffel_service.dart';
import 'passenger_details_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  // 1. The "Mitt" - Catching the variables passed from the Search Dashboard
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
  late Future<List<dynamic>> _flightsFuture;

  @override
  void initState() {
    super.initState();
    // 2. Plugging those dynamic variables directly into your live API Service
    _flightsFuture = DuffelService.searchFlights(widget.origin, widget.destination, widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        // 3. Dynamic App Bar Title!
        title: Text('${widget.origin} to ${widget.destination}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _flightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No flights found for this route.', style: TextStyle(color: Colors.white)));
          }

          final flights = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flights.length,
            itemBuilder: (context, index) {
              final flight = flights[index];
              final airline = flight['owner']['name'] ?? 'Unknown Airline';
              final price = flight['total_amount'];
              final currency = flight['total_currency'];
              final flightId = flight['id'];

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.flight, color: Colors.white),
                  ),
                  title: Text(airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('ID: ${flightId.substring(0, 16)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$$price', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(currency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  onTap: () {
                    // 4. Handoff to the Passenger Checkout!
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
