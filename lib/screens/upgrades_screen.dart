import 'package:flutter/material.dart';
import 'boarding_pass_screen.dart';

class UpgradesScreen extends StatefulWidget {
  final dynamic flight;

  const UpgradesScreen({super.key, required this.flight});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  bool _addCarryOn = false;
  bool _addCheckedBag = false;
  String _selectedSeat = 'Standard Economy';

  final double _carryOnPrice = 40.0;
  final double _checkedBagPrice = 60.0;
  final Map<String, double> _seatPrices = {
    'Standard Economy': 0.0,
    'Extra Legroom': 45.0,
    'First Class': 150.0,
  };

  double get _calculatedTotal {
    double basePrice = 0.0;
    // Safely parse the price whether it came in as a double, int, or String
    if (widget.flight['price'] != null) {
      basePrice = double.tryParse(widget.flight['price'].toString()) ?? 0.0;
    }
    
    double total = basePrice;
    if (_addCarryOn) total += _carryOnPrice;
    if (_addCheckedBag) total += _checkedBagPrice;
    total += _seatPrices[_selectedSeat]!;
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.flight['currency'] ?? 'USD';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Customize Your Trip'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Baggage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            
            // --- BAGGAGE SWITCHES ---
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Carry-on Bag', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('+\$40.00 • Overhead bin access', style: TextStyle(color: Colors.grey)),
                    secondary: const Icon(Icons.luggage, color: Colors.blueAccent),
                    activeColor: Colors.blueAccent,
                    value: _addCarryOn,
                    onChanged: (bool value) => setState(() => _addCarryOn = value),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  SwitchListTile(
                    title: const Text('Checked Bag', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('+\$60.00 • Max 50 lbs', style: TextStyle(color: Colors.grey)),
                    secondary: const Icon(Icons.work, color: Colors.blueAccent),
                    activeColor: Colors.blueAccent,
                    value: _addCheckedBag,
                    onChanged: (bool value) => setState(() => _addCheckedBag = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Seat Selection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),

            // --- SEAT RADIO BUTTONS ---
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: _seatPrices.keys.map((String seatType) {
                  final priceLabel = _seatPrices[seatType] == 0 
                      ? 'Included' 
                      : '+\$${_seatPrices[seatType]!.toStringAsFixed(2)}';
                      
                  return RadioListTile<String>(
                    title: Text(seatType, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(priceLabel, style: const TextStyle(color: Colors.grey)),
                    activeColor: Colors.blueAccent,
                    value: seatType,
                    groupValue: _selectedSeat,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSeat = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // --- DYNAMIC TOTAL & CHECKOUT BUTTON ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('${_calculatedTotal.toStringAsFixed(2)} $currency', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: Card(
                            color: Color(0xFF1E293B),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.blueAccent),
                                  SizedBox(height: 16),
                                  Text('Processing Payment...', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    await Future.delayed(const Duration(seconds: 2));

                    if (context.mounted) {
                      Navigator.of(context).pop(); 
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoardingPassScreen(flight: widget.flight),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm & Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}