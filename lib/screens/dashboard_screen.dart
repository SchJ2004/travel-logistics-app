import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- New Import for links!
import 'login_screen.dart';
import 'flight_details_screen.dart'; 
import 'flight_results_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FlightSearchTab(),
    const MyTripsTab(),
    const AirportAmenitiesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine if we are on a wide screen (Web/Tablet) or narrow screen (Phone)
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      // Only show the Bottom Navigation if we are NOT on desktop
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.luggage), label: 'My Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.local_cafe), label: 'Airport'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: isDesktop 
            // DESKTOP LAYOUT: Side Navigation Rail + Content
            ? Row(
                children: [
                  NavigationRail(
                    backgroundColor: const Color(0xFF1E293B),
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (int index) => setState(() => _currentIndex = index),
                    labelType: NavigationRailLabelType.all,
                    unselectedIconTheme: const IconThemeData(color: Colors.grey),
                    selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
                    unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                    selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent),
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.flight_takeoff), label: Text('Search')),
                      NavigationRailDestination(icon: Icon(Icons.luggage), label: Text('Trips')),
                      NavigationRailDestination(icon: Icon(Icons.local_cafe), label: Text('Airport')),
                      NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1, color: Colors.black),
                  // The main content area
                  Expanded(
                    child: Center(
                      // Constrain the width on desktop so it doesn't stretch infinitely
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _screens[_currentIndex],
                      ),
                    ),
                  ),
                ],
              )
            // MOBILE LAYOUT: Just the content (Bottom Nav handles routing)
            : _screens[_currentIndex],
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
  
  bool _isRoundTrip = false;
  DateTime? _departureDate;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    _loadSavedHomeAirport();
  }

  Future<void> _loadSavedHomeAirport() async {
    final prefs = await SharedPreferences.getInstance();
    final homeAirport = prefs.getString('home_airport');
    if (homeAirport != null && homeAirport.isNotEmpty) {
      setState(() {
        _originController.text = homeAirport;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(_departureDate!)) {
            _returnDate = null; 
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Find a Flight', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('One Way')),
                  selected: !_isRoundTrip,
                  onSelected: (selected) => setState(() => _isRoundTrip = false),
                  selectedColor: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Round Trip')),
                  selected: _isRoundTrip,
                  onSelected: (selected) => setState(() => _isRoundTrip = true),
                  selectedColor: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originController,
                  decoration: const InputDecoration(labelText: 'Origin (e.g. JFK)', border: OutlineInputBorder()),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(labelText: 'Dest (e.g. LAX)', border: OutlineInputBorder()),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(_departureDate == null ? 'Depart' : '${_departureDate!.month}/${_departureDate!.day}/${_departureDate!.year}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isRoundTrip) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(_returnDate == null ? 'Return' : '${_returnDate!.month}/${_returnDate!.day}/${_returnDate!.year}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                final origin = _originController.text.isNotEmpty ? _originController.text : 'ORG';
                final destination = _destinationController.text.isNotEmpty ? _destinationController.text : 'DST';
                final date = _departureDate != null ? '${_departureDate!.month}/${_departureDate!.day}/${_departureDate!.year}' : 'Select Date';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlightResultsScreen(
                      origin: origin,
                      destination: destination,
                      departureDate: date,
                    ),
                  ),
                );
              },
              child: const Text('Search Flights', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final mockFlight = {
      'id': '109283',
      'airline': 'Duffel Airways',
      'origin': 'RIC',
      'destination': 'JFK',
      'price': 142.50,
      'currency': 'USD',
      'departure_date': '2026-06-15',
      'passenger_name': Supabase.instance.client.auth.currentUser?.email ?? 'Guest',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Trips', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const Icon(Icons.flight, color: Colors.blueAccent),
              title: const Text('RIC to JFK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('June 15, 2026', style: TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FlightDetailsScreen(flight: mockFlight)),
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
// TAB 3: AIRPORT AMENITIES (DIRECT SITE LINKS)
// ==========================================
class AirportAmenitiesTab extends StatelessWidget {
  const AirportAmenitiesTab({super.key});

  // UPDATED: Now accepts a direct web address instead of generating a search
  Future<void> _launchDirectUrl(BuildContext context, String targetUrl) async {
    final url = Uri.parse(targetUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the website.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explore JFK Airport', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Terminal 4 • New York', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),

          // --- VIP LOUNGES ---
          const Text('VIP Lounges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SkyHigh Premium Lounge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('85% Full', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Near Gate B32 • Showers, Hot Buffet, Full Bar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      // Direct link to LoungeBuddy
                      onPressed: () => _launchDirectUrl(context, 'https://www.loungebuddy.com/'),
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      label: const Text('Find Passes', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- GROUND TRANSPORTATION ---
          const Text('Ground Transport', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notice we now pass the exact URL as the 4th item!
              _buildActionCard(context, Icons.directions_car, 'Rental Cars', 'https://www.enterprise.com/'),
              _buildActionCard(context, Icons.directions_bus, 'Bus/Shuttle', 'https://www.flixbus.com/'),
              _buildActionCard(context, Icons.directions_boat, 'Ferry Tix', 'https://www.ferry.nyc/'),
            ],
          ),
          const SizedBox(height: 24),

          // --- STAY & PLAY ---
          const Text('Stay & Play', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Passing specific URLs for these partners
                _buildHorizontalCard(context, Icons.hotel, 'Hotels', 'Find stays near JFK', 'https://www.expedia.com/'),
                _buildHorizontalCard(context, Icons.restaurant, 'Dining', 'Reserve a table', 'https://www.opentable.com/'),
                _buildHorizontalCard(context, Icons.pedal_bike, 'Experiences', 'Tours & Rentals', 'https://www.viator.com/'),
                _buildHorizontalCard(context, Icons.museum, 'Museums', 'Skip-the-line tickets', 'https://www.getyourguide.com/'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // UPDATED: Added a `targetUrl` parameter
  Widget _buildActionCard(BuildContext context, IconData icon, String label, String targetUrl) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          // Triggers the direct URL launcher
          onTap: () => _launchDirectUrl(context, targetUrl),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Icon(icon, size: 32, color: Colors.blueAccent),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Added a `targetUrl` parameter
  Widget _buildHorizontalCard(BuildContext context, IconData icon, String title, String subtitle, String targetUrl) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          // Triggers the direct URL launcher
          onTap: () => _launchDirectUrl(context, targetUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.blueAccent),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 4: PROFILE & SETTINGS
// ==========================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _homeAirportController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeAirportController.text = prefs.getString('home_airport') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_airport', _homeAirportController.text.trim().toUpperCase());
    
    if (mounted) {
      FocusScope.of(context).unfocus(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Unknown User';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile & Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
              title: const Text('Account Email', style: TextStyle(color: Colors.grey, fontSize: 12)),
              subtitle: Text(userEmail, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Home Airport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _homeAirportController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Airport Code (e.g. RIC)', border: OutlineInputBorder()),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22.0),
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48), // Spacer replacement for scrolling
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}