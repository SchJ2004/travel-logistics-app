import 'package:flutter/material.dart';
import '../services/duffel_service.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final String offerId;
  final String airline;
  final String price;

  const PassengerDetailsScreen({
    super.key,
    required this.offerId,
    required this.airline,
    required this.price,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  DateTime? _dob;
  String _gender = 'm'; // Duffel expects 'm' or 'f'
  bool _isProcessing = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      setState(() => _dob = picked);
    }
  }

  // ==========================================
  // LIVE CHECKOUT FUNCTION
  // ==========================================
  Future<void> _processCheckout() async {
    // 1. Validate the form
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _dob == null || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required passenger details.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 2. Format the Date of Birth to YYYY-MM-DD
      final formattedDob = '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';

      // 3. Send to Duffel!
      final bookingReference = await DuffelService.createTestOrder(
        widget.offerId,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        formattedDob,
        _gender,
        _emailController.text.trim(),
        widget.price,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
        // 4. Show the massive success message with the Booking Code!
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Ticket Confirmed! ✈️', style: TextStyle(color: Colors.white)),
            content: Text('Your flight is booked.\n\nBooking Reference (PNR):\n$bookingReference', style: const TextStyle(color: Colors.greenAccent, fontSize: 18)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to search
                },
                child: const Text('Back to Home', style: TextStyle(color: Colors.blueAccent)),
              ),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Passenger Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flight Summary Card
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Offer: ${widget.offerId.substring(0, 12)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Text('\$${widget.price}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Legal Name', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Must match your government-issued ID exactly.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('TSA Requirements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_dob == null ? 'Date of Birth' : '${_dob!.month}/${_dob!.day}/${_dob!.year}', style: const TextStyle(color: Colors.white)),
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'm', child: Text('Male')),
                      DropdownMenuItem(value: 'f', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Contact Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address for E-Ticket', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email, color: Colors.grey)),
            ),
            const SizedBox(height: 32),

            // Checkout Button (Now completely hardwired to the live API)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _isProcessing ? null : _processCheckout,
                child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Proceed to Secure Checkout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}