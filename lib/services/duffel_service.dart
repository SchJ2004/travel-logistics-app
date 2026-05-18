import 'package:supabase_flutter/supabase_flutter.dart';

class DuffelService {
  
  // ==========================================
  // FUNCTION 1: SEARCH FLIGHTS (SECURE ROUTE)
  // ==========================================
  static Future<List<dynamic>> searchFlights(String origin, String destination, String date) async {
    try {
      // 1. We seamlessly call your Supabase Cloud Function. 
      // Supabase automatically handles all CORS headers and browser security!
      final response = await Supabase.instance.client.functions.invoke(
        'search-flights',
        body: {
          "origin": origin,
          "destination": destination,
          "departureDate": date
        },
      );

      if (response.status == 200) {
        final edgeFlights = response.data['flights'] as List<dynamic>;
        
        // 2. We remap the clean edge function data back into the structure 
        // your flight_results_screen.dart UI is currently expecting to see.
        return edgeFlights.map((f) => {
          'owner': {'name': f['airline']},
          'total_amount': f['price'],
          'currency': f['currency']
        }).toList();
        
      } else {
        throw Exception('Backend error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Supabase: $e');
    }
  }

  // ==========================================
  // FUNCTION 2: MOCKED CHECKOUT FOR WEB LAUNCH
  // ==========================================
  static Future<String> createTestOrder(String offerId, String firstName, String lastName, String dob, String gender, String email, String phoneNumber, String price) async {
    // Note: Because we removed direct Duffel access, we are mocking the ticket 
    // generation so you can get the web UI live and test the Stripe flow today.
    // Next week, we will build a 'book-flight' edge function to handle real ticketing!
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate network processing
    return "PRO-WANDERLUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  }
}