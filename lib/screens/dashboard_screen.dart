import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
    const DashboardScreen({super.key});

    @override
    State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
    int _selectedIndex = 0;

    // --- Our 4 Main Tabs ---
    static const List<Widget> _widgetOptions = <Widget>[
        FlightSearchTab(),
        MyTripsTab(), 
        AirportLogisticsTab(), 
        ProfileTab(),
    ];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Travel Logistics')),
            body: _widgetOptions.elementAt(_selectedIndex),
            bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: 'Search'),
                    BottomNavigationBarItem(icon: Icon(Icons.luggage), label: 'My Trips'),
                    BottomNavigationBarItem(icon: Icon(Icons.local_cafe), label: 'Airport'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.blueAccent,
                unselectedItemColor: Colors.grey,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
            ),
        );
    }
}

// ==========================================
// TAB 1: FLIGHT SEARCH (Duffel API)
// ==========================================
class FlightSearchTab extends StatefulWidget {
    const FlightSearchTab({super.key});

    @override
    State<FlightSearchTab> createState() => _FlightSearchTabState();
}

class _FlightSearchTabState extends State<FlightSearchTab> {
    final _originController = TextEditingController();
    final _destinationController = TextEditingController();
    
    DateTime? _selectedDate; 
    bool _isLoading = false;
    bool _hasSearched = false;
    List<dynamic> _flights = []; 

    Future<void> _pickDate() async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)), 
            firstDate: DateTime.now(), 
            lastDate: DateTime.now().add(const Duration(days: 365)), 
        );
        if (picked != null && picked != _selectedDate) {
            setState(() => _selectedDate = picked);
        }
    }

    Future<void> _searchFlights() async {
        final origin = _originController.text.trim().toUpperCase();
        final destination = _destinationController.text.trim().toUpperCase();

        if (origin.isEmpty || destination.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter airports')));
            return;
        }
        if (_selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
            return;
        }

        setState(() {
            _isLoading = true;
            _hasSearched = false;
        });

        try {
            final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

            final response = await Supabase.instance.client.functions.invoke(
                'search-flights',
                body: {'origin': origin, 'destination': destination, 'departureDate': formattedDate},
            );

            setState(() {
                _flights = response.data['flights'] ?? [];
                _hasSearched = true;
            });
        } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
        } finally {
            if (mounted) setState(() => _isLoading = false);
        }
    }

    Future<void> _saveFlight(dynamic flight) async {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;

        final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

        try {
            await Supabase.instance.client.from('saved_flights').insert({
                'user_id': user.id,
                'flight_id': flight['id'],
                'airline': flight['airline'] ?? 'Unknown',
                'price': flight['price'],
                'currency': flight['currency'] ?? 'USD',
                'origin': _originController.text.trim().toUpperCase(),
                'destination': _destinationController.text.trim().toUpperCase(),
                'departure_date': formattedDate,
            });

            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight saved to My Trips!'), backgroundColor: Colors.green));
        } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent));
        }
    }

    @override
    void dispose() {
        _originController.dispose();
        _destinationController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text('Find a Flight', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                        children: [
                            Expanded(child: TextField(controller: _originController, decoration: const InputDecoration(labelText: 'Origin', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters)),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Dest', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters)),
                        ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_selectedDate == null ? 'Select Departure Date' : 'Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), alignment: Alignment.centerLeft),
                    ),
                    const SizedBox(height: 24),
                    _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(onPressed: _searchFlights, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: const Text('Search Flights', style: TextStyle(fontSize: 18))),
                    const SizedBox(height: 24),
                    if (_hasSearched && _flights.isEmpty) const Center(child: Text('No flights found for this route.', style: TextStyle(fontSize: 16))),
                    if (_flights.isNotEmpty)
                        Expanded(
                            child: ListView.builder(
                                itemCount: _flights.length,
                                itemBuilder: (context, index) {
                                    final flight = _flights[index];
                                    return Card(
                                        elevation: 3, margin: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.flight, color: Colors.white)),
                                            title: Text(flight['airline'] ?? 'Unknown Airline', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            subtitle: Text('ID: ${flight['id'].toString().substring(0, 8)}...'),
                                            trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    Column(
                                                        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                            Text('${flight['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                                            Text(flight['currency'] ?? 'USD', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                        ],
                                                    ),
                                                    const SizedBox(width: 12),
                                                    IconButton(icon: const Icon(Icons.bookmark_add_outlined, color: Colors.blueAccent), tooltip: 'Save Flight', onPressed: () => _saveFlight(flight)),
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

// ==========================================
// TAB 2: MY TRIPS (Supabase Database)
// ==========================================
class MyTripsTab extends StatelessWidget {
    const MyTripsTab({super.key});

    Future<void> _deleteFlight(BuildContext context, String id) async {
        try {
            await Supabase.instance.client.from('saved_flights').delete().match({'id': id});
            if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight removed'), backgroundColor: Colors.orange));
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            }
        } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
    }

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text('Saved Itineraries', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: Supabase.instance.client.from('saved_flights').select().order('created_at', ascending: false),
                            builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                if (snapshot.hasError) return Center(child: Text('Error loading trips: ${snapshot.error}'));
                                
                                final flights = snapshot.data ?? [];
                                if (flights.isEmpty) return const Center(child: Text('You have no saved flights yet. Search and click the bookmark icon!'));

                                return ListView.builder(
                                    itemCount: flights.length,
                                    itemBuilder: (context, index) {
                                        final flight = flights[index];
                                        return Card(
                                            elevation: 2,
                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                            child: ListTile(
                                                leading: const Icon(Icons.luggage, color: Colors.blueAccent),
                                                title: Text('${flight['origin']} to ${flight['destination']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Text('${flight['airline']} • Date: ${flight['departure_date']}'),
                                                trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                        Text('${flight['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                                        IconButton(
                                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                            onPressed: () => _deleteFlight(context, flight['id']),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        );
                                    },
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }
}

// ==========================================
// TAB 3: AIRPORT LOGISTICS (Static UI)
// ==========================================
class AirportLogisticsTab extends StatefulWidget {
    const AirportLogisticsTab({super.key});

    @override
    State<AirportLogisticsTab> createState() => _AirportLogisticsTabState();
}

class _AirportLogisticsTabState extends State<AirportLogisticsTab> {
    String _selectedTerminal = 'Terminal A';

    final List<Map<String, String>> _amenities = [
        {'name': 'Starbucks', 'type': 'Coffee', 'gate': 'A12', 'status': 'Open'},
        {'name': 'Delta Sky Club', 'type': 'Lounge', 'gate': 'A15', 'status': 'Open'},
        {'name': 'Shake Shack', 'type': 'Food', 'gate': 'A8', 'status': 'Closes at 10 PM'},
    ];

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text('Airport Logistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                        value: _selectedTerminal,
                        decoration: const InputDecoration(labelText: 'Select Terminal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.domain)),
                        items: ['Terminal A', 'Terminal B', 'Terminal C']
                                .map((terminal) => DropdownMenuItem(value: terminal, child: Text(terminal)))
                                .toList(),
                        onChanged: (value) {
                            if (value != null) {
                                setState(() => _selectedTerminal = value);
                            }
                        },
                    ),
                    const SizedBox(height: 24),
                    Card(
                        elevation: 4,
                        color: const Color(0xFF1E293B).withOpacity(0.5), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                                children: [
                                    const Icon(Icons.security, size: 40, color: Colors.greenAccent),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                const Text('TSA Security Checkpoint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text('Estimated wait for $_selectedTerminal', style: const TextStyle(color: Colors.grey)),
                                            ],
                                        ),
                                    ),
                                    const Text('15 Min', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                ],
                            ),
                        ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Food & Lounges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                        child: ListView.builder(
                            itemCount: _amenities.length,
                            itemBuilder: (context, index) {
                                final item = _amenities[index];
                                return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                        leading: CircleAvatar(
                                            backgroundColor: item['type'] == 'Coffee' ? Colors.brown : (item['type'] == 'Lounge' ? Colors.purple : Colors.orange),
                                            child: Icon(item['type'] == 'Coffee' ? Icons.coffee : (item['type'] == 'Lounge' ? Icons.weekend : Icons.fastfood), color: Colors.white),
                                        ),
                                        title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('Near Gate ${item['gate']} • ${item['status']}'),
                                        trailing: const Icon(Icons.chevron_right),
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

// ==========================================
// TAB 4: PROFILE 
// ==========================================
class ProfileTab extends StatelessWidget {
    const ProfileTab({super.key});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: ElevatedButton.icon(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ),
        );
    }
}