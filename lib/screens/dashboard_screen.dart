import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'flight_results_screen.dart';
import 'ai_agent_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FlightSearchTab(),
    const UpcomingTripsTab(),
    const AiAgentScreen(),
    const AirportAmenitiesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.luggage), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Agent'),
          BottomNavigationBarItem(icon: Icon(Icons.local_airport), label: 'Airport Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: LIVE FLIGHT SEARCH FORM
// ==========================================
class FlightSearchTab extends StatefulWidget {
  const FlightSearchTab({super.key});

  @override
  State<FlightSearchTab> createState() => _FlightSearchTabState();
}

class _FlightSearchTabState extends State<FlightSearchTab> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _departureDate;
  DateTime? _returnDate;

  Future<void> _selectDate(BuildContext context, bool isReturn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnDate = picked;
        } else {
          _departureDate = picked;
        }
      });
    }
  }

  void _triggerSearch() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty || _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Origin, Destination, and Departure Date.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // CRITICAL FIX: Formatting strictly to YYYY-MM-DD for Duffel!
    final formattedDate = '${_departureDate!.year}-${_departureDate!.month.toString().padLeft(2, '0')}-${_departureDate!.day.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlightResultsScreen(
          origin: _originController.text.trim().toUpperCase(),
          destination: _destinationController.text.trim().toUpperCase(),
          date: formattedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---> HERE IS THE PROOF OF LIFE CHANGE <---
          const Text('Where to next, Joshua?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Search the global aviation grid.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),

          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _originController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: 'Origin (e.g. JFK)', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.flight_takeoff, color: Colors.blueAccent), border: OutlineInputBorder(), counterText: ''),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: 'Destination (e.g. LHR)', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.flight_land, color: Colors.blueAccent), border: OutlineInputBorder(), counterText: ''),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _departureDate == null ? 'Depart' : '${_departureDate!.month}/${_departureDate!.day}/${_departureDate!.year}', 
                                    style: TextStyle(color: _departureDate == null ? Colors.grey : Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _returnDate == null ? 'Return (Opt)' : '${_returnDate!.month}/${_returnDate!.day}/${_returnDate!.year}', 
                                    style: TextStyle(color: _returnDate == null ? Colors.grey : Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      onPressed: _triggerSearch,
                      child: const Text('Search Flights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: LIVE UPCOMING TRIPS FROM SUPABASE
// ==========================================
class UpcomingTripsTab extends StatelessWidget {
  const UpcomingTripsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please log in to view your digital wallet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('trips').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final trips = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Digital Wallet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Your upcoming adventures', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),
              
              if (trips.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.luggage, size: 64, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No upcoming trips booked yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...trips.map((trip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildBoardingPassCard(
                      context,
                      airline: trip['airline'] ?? 'Unknown',
                      pnr: trip['pnr'] ?? 'ERROR',
                      origin: trip['origin'] ?? '???',
                      destination: trip['destination'] ?? '???',
                      date: trip['flight_date'] ?? 'TBD',
                      status: 'CONFIRMED',
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoardingPassCard(BuildContext context, {required String airline, required String pnr, required String origin, required String destination, required String date, required String status}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.flight_takeoff, color: Colors.white, size: 20), const SizedBox(width: 8), Text(airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(origin, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)), const Text('Departure', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                const Icon(Icons.flight_outlined, color: Colors.blueAccent, size: 32),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(destination, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)), const Text('Arrival', style: TextStyle(color: Colors.grey, fontSize: 12))]),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(height: 1, color: Colors.grey.withOpacity(0.3))),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(date, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('BOOKING REF (PNR)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(pnr, style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.qr_code_2, color: Colors.black, size: 64)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: AIRPORT AMENITIES (GENERALIZED)
// ==========================================
class AirportAmenitiesTab extends StatefulWidget {
  const AirportAmenitiesTab({super.key});

  @override
  State<AirportAmenitiesTab> createState() => _AirportAmenitiesTabState();
}

class _AirportAmenitiesTabState extends State<AirportAmenitiesTab> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _launchDirectUrl(BuildContext context, String targetUrl) async {
    final url = Uri.parse(targetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the website.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Airport Guide', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Lounges, Transport & Amenities', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search airports (e.g., MIA, LHR)',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

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
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Text('85% Full', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Showers, Hot Buffet, Full Bar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
          const Text('Ground Transport', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionCard(context, Icons.directions_car, 'Rental Cars', 'https://www.enterprise.com/'),
              _buildActionCard(context, Icons.directions_bus, 'Bus/Shuttle', 'https://www.flixbus.com/'),
              _buildActionCard(context, Icons.local_taxi, 'Rideshare', 'https://www.uber.com/'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Stay & Play', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHorizontalCard(context, Icons.hotel, 'Hotels', 'Find stays near terminal', 'https://www.expedia.com/'),
                _buildHorizontalCard(context, Icons.restaurant, 'Dining', 'Reserve a table', 'https://www.opentable.com/'),
                _buildHorizontalCard(context, Icons.pedal_bike, 'Experiences', 'Tours & Rentals', 'https://www.viator.com/'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, String targetUrl) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _launchDirectUrl(context, targetUrl),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(children: [Icon(icon, size: 32, color: Colors.blueAccent), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, IconData icon, String title, String subtitle, String targetUrl) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _launchDirectUrl(context, targetUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon, size: 32, color: Colors.blueAccent), const SizedBox(height: 12), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 4: PROFILE & AUTHENTICATION
// ==========================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signUp(email: _emailController.text.trim(), password: _passwordController.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e'), backgroundColor: Colors.redAccent));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48, 
              backgroundColor: Colors.blueAccent, 
              child: Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Welcome Back!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(session.user.email ?? 'Traveler', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), 
              onPressed: _signOut, 
              icon: const Icon(Icons.logout, color: Colors.white), 
              label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.lock_person, size: 64, color: Colors.blueAccent),
          const SizedBox(height: 16),
          const Text('Secure Login', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('Access your tickets and itineraries.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController, 
            style: const TextStyle(color: Colors.white), 
            keyboardType: TextInputType.emailAddress, 
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController, 
            style: const TextStyle(color: Colors.white), 
            obscureText: true, 
            decoration: const InputDecoration(labelText: 'Password (min 6 chars)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock, color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16)), 
                      onPressed: _signIn, 
                      child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(vertical: 16)), 
                      onPressed: _signUp, 
                      child: const Text('Create Account', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}