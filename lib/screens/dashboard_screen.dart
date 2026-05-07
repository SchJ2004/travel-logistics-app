import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'flight_details_screen.dart'; // <-- IMPORTED YOUR NEW SCREEN!

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
// TAB 1: FLIGHT SEARCH
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
                      // --- ROUTING WIRED UP HERE ---
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FlightDetailsScreen(flight: flight))),
                      
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
// TAB 2: MY TRIPS 
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
                        // --- ROUTING WIRED UP HERE ---
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FlightDetailsScreen(flight: flight))),

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
// TAB 3: AIRPORT LOGISTICS (Yelp API + Filters)
// ==========================================
class AirportLogisticsTab extends StatefulWidget {
  const AirportLogisticsTab({super.key});

  @override
  State<AirportLogisticsTab> createState() => _AirportLogisticsTabState();
}

class _AirportLogisticsTabState extends State<AirportLogisticsTab> {
  final _airportCodeController = TextEditingController();
  String _selectedTerminal = 'Terminal A';
  
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Coffee', 'Lounges'];
  
  bool _isLoading = false;
  bool _hasSearched = false;
  List<dynamic> _amenities = [];

  Future<void> _fetchAmenities() async {
    final airport = _airportCodeController.text.trim().toUpperCase();
    if (airport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an airport code')));
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      String searchTerm = 'food lounge $_selectedTerminal'; 
      if (_selectedCategory == 'Food') searchTerm = 'restaurant $_selectedTerminal';
      if (_selectedCategory == 'Coffee') searchTerm = 'coffee $_selectedTerminal';
      if (_selectedCategory == 'Lounges') searchTerm = 'airport lounge $_selectedTerminal';

      final response = await Supabase.instance.client.functions.invoke(
        'airport-amenities',
        body: {'location': '$airport Airport', 'term': searchTerm},
      );

      setState(() {
        _amenities = response.data['businesses'] ?? [];
        _hasSearched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _airportCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Airport Logistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _airportCodeController,
                  decoration: const InputDecoration(labelText: 'Airport (e.g. JFK)', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedTerminal,
                  decoration: const InputDecoration(labelText: 'Select Area', border: OutlineInputBorder()),
                  items: ['Terminal A', 'Terminal B', 'Terminal C', 'Main Terminal', 'International']
                      .map((terminal) => DropdownMenuItem(value: terminal, child: Text(terminal)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedTerminal = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _fetchAmenities,
                icon: const Icon(Icons.search),
                label: const Text('Find Amenities', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
          
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    selectedColor: Colors.blueAccent.withOpacity(0.3),
                    checkmarkColor: Colors.blueAccent,
                    onSelected: (bool selected) {
                      setState(() => _selectedCategory = category);
                      if (_hasSearched) _fetchAmenities(); 
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_hasSearched && _amenities.isEmpty)
            const Center(child: Text('No amenities found for this filter.', style: TextStyle(fontSize: 16))),

          Expanded(
            child: ListView.builder(
              itemCount: _amenities.length,
              itemBuilder: (context, index) {
                final item = _amenities[index];
                final bool isClosed = item['is_closed'] ?? false;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item['image_url'], width: 60, height: 60, fit: BoxFit.cover),
                          )
                        : const CircleAvatar(child: Icon(Icons.fastfood)),
                    title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⭐ ${item['rating']} (${item['review_count']} reviews)'),
                        Text(
                          isClosed ? 'Currently Closed' : 'Currently Open', 
                          style: TextStyle(color: isClosed ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
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