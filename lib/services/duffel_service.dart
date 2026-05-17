import 'dart:convert';
import 'package:http/http.dart' as http;

class DuffelService {
  static const String _baseUrl = 'https://api.duffel.com/air';
  // Using your test key from earlier
  static const String _apiKey = 'duffel_test_U-hygRGC8qICPu8jhyrX8hy6A5bLaYNmz19AZhWhAM7'; 

  // ==========================================
  // FUNCTION 1: SEARCH FLIGHTS
  // ==========================================
  static Future<List<dynamic>> searchFlights(String origin, String destination, String date) async {
    // THE FIX: We removed the old parsing logic! 
    // The UI now perfectly sends YYYY-MM-DD, so we just pass it straight to Duffel.

    final url = Uri.parse('$_baseUrl/offer_requests');
    
    final body = jsonEncode({
      "data": {
        "slices": [
          {
            "origin": origin.toUpperCase(),
            "destination": destination.toUpperCase(),
            "departure_date": date // <-- Directly using the pre-formatted date here!
          }
        ],
        "passengers": [{"type": "adult"}],
        "cabin_class": "economy"
      }
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Duffel-Version': 'v2',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['offers'] as List<dynamic>;
    } else {
      throw Exception('Failed to load flights: ${response.body}');
    }
  }

  // ==========================================
  // FUNCTION 2: CREATE TICKET (PURCHASE)
  // ==========================================
  static Future<String> createTestOrder(String offerId, String firstName, String lastName, String dob, String gender, String email, String phoneNumber, String price) async {
    final offerUrl = Uri.parse('$_baseUrl/offers/$offerId');
    final offerResponse = await http.get(offerUrl, headers: {'Authorization': 'Bearer $_apiKey', 'Duffel-Version': 'v2'});

    if (offerResponse.statusCode != 200) throw Exception('Failed to fetch offer details.');
    
    final offerData = jsonDecode(offerResponse.body);
    final passengerId = offerData['data']['passengers'][0]['id'];
    
    // Auto-assign title based on gender
    final passengerTitle = gender == 'm' ? 'mr' : 'ms';

    final orderUrl = Uri.parse('$_baseUrl/orders');
    final body = jsonEncode({
      "data": {
        "type": "instant",
        "payments": [{"type": "balance", "amount": price, "currency": "USD"}],
        "selected_offers": [offerId],
        "passengers": [
          {
            "id": passengerId,
            "title": passengerTitle, 
            "given_name": firstName,
            "family_name": lastName,
            "born_on": dob,
            "gender": gender,
            "email": email,
            "phone_number": phoneNumber // <-- Dynamic Phone Number included
          }
        ]
      }
    });

    final orderResponse = await http.post(
      orderUrl, 
      headers: {'Authorization': 'Bearer $_apiKey', 'Duffel-Version': 'v2', 'Content-Type': 'application/json'}, 
      body: body
    );

    if (orderResponse.statusCode == 201) {
      final orderData = jsonDecode(orderResponse.body);
      return orderData['data']['booking_reference']; 
    } else {
      throw Exception('Failed to book flight: ${orderResponse.body}');
    }
  }
}