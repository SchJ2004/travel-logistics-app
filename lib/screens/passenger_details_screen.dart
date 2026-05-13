import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/duffel_service.dart';
import '../services/stripe_service.dart'; // <-- Stripe Import Added

class PassengerDetailsScreen extends StatefulWidget {
  final String offerId;
  final String airline;
  final String price;
  final String origin;
  final String destination;
  final String date;

  const PassengerDetailsScreen({
    super.key,
    required this.offerId,
    required this.airline,
    required this.price,
    this.origin = 'TBD',
    this.destination = 'TBD',
    this.date = 'TBD',
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _dob;
  String _gender = 'm'; 
  bool _isProcessing = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent, 
            onPrimary: Colors.white, 
            surface: Color(0xFF1E293B), 
            onSurface: Colors.white
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _processCheckout() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _dob == null || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all details.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. GENERATE STRIPE PAYMENT LINK
      final checkoutUrl = await StripeService.createCheckoutSession(
        widget.airline, 
        widget.price
      );

      if (checkoutUrl == null) throw Exception("Could not generate payment link.");

      // 2. SEND USER TO STRIPE
      await StripeService.launchCheckout(checkoutUrl);

      // 3. BOOK WITH DUFFEL (Simulating post-payment success)
      final formattedDob = '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';
      
      String formattedPhone = _phoneController.text.trim();
      if (!formattedPhone.startsWith('+')) formattedPhone = '+1$formattedPhone';

      final bookingReference = await DuffelService.createTestOrder(
        widget.offerId,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        formattedDob,
        _gender,
        _emailController.text.trim(),
        formattedPhone, 
        widget.price,
      );

      // 4. SAVE TO SUPABASE
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.from('trips').insert({
          'user_id': user.id,
          'pnr': bookingReference,
          'airline': widget.airline,
          'origin': widget.origin,
          'destination': widget.destination,
          'flight_date': widget.date,
        });
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Ticket Confirmed! ✈️', style: TextStyle(color: Colors.white)),
            content: Text('Your flight is booked and saved.\n\nBooking Reference:\n$bookingReference', style: const TextStyle(color: Colors.greenAccent, fontSize: 18)),
            actions: [
              TextButton(
                onPressed: () { 
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                }, 
                child: const Text('Back to Home', style: TextStyle(color: Colors.blueAccent))
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF1E293B), title: const Text('Passenger Details', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
                    Text('\$${widget.price}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Legal Name', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _firstNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _lastNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: InkWell(onTap: () => _selectDate(context), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Text(_dob == null ? 'Date of Birth' : '${_dob!.month}/${_dob!.day}/${_dob!.year}', style: const TextStyle(color: Colors.white))))),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(value: _gender, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'm', child: Text('Male')), DropdownMenuItem(value: 'f', child: Text('Female'))], onChanged: (value) => setState(() => _gender = value!))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Contact Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _emailController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email, color: Colors.grey))),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', hintText: 'e.g. 7575550199', hintStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone, color: Colors.grey))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _isProcessing ? null : _processCheckout,
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Proceed to Secure Checkout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}