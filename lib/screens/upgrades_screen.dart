import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
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

  // --- THE STRIPE CHECKOUT FUNCTION ---
  Future<void> _launchCheckout(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open checkout.')));
    }
  }

  // --- PASTE YOUR STRIPE LINKS HERE ---
  final String _monthlyLink = 'PASTE_YOUR_MONTHLY_TEST_LINK_HERE';
  final String _yearlyLink = 'PASTE_YOUR_YEARLY_TEST_LINK_HERE';

  final double _carryOnPrice = 40.0;
  final double _checkedBagPrice = 60.0;
  final Map<String, double> _seatPrices = {
    'Standard Economy': 0.0,
    'Extra Legroom': 45.0,
    'First Class': 150.0,
  };

  double get _calculatedTotal {
    double basePrice = 0.0;
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- THE WANDERLUST PRO UPSELL CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], 
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.yellowAccent),
                              SizedBox(width: 8),
                              Text('Unlock Wanderlust Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Skip booking fees, get unlimited AI routing, and priority support.', style: TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                                  onPressed: () => _launchCheckout(_monthlyLink),
                                  child: const Text('7-Day Trial\n\$9 / mo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                  onPressed: () => _launchCheckout(_yearlyLink),
                                  child: const Text('7-Day Trial\n\$99 / yr', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Baggage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    
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

                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: _seatPrices.keys.map((String seatType) {
                          final priceLabel = _seatPrices[seatType] == 0 ? 'Included' : '+\$${_seatPrices[seatType]!.toStringAsFixed(2)}';
                          return RadioListTile<String>(
                            title: Text(seatType, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(priceLabel, style: const TextStyle(color: Colors.grey)),
                            activeColor: Colors.blueAccent,
                            value: seatType,
                            groupValue: _selectedSeat,
                            onChanged: (String? value) => setState(() => _selectedSeat = value!),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            // --- BOTTOM CHECKOUT BAR ---
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text('${_calculatedTotal.toStringAsFixed(2)} $currency', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                                    Text('Processing Flight...', style: TextStyle(color: Colors.white)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Flight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}