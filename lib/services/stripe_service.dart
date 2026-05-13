import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  // ---> PASTE YOUR STRIPE SECRET KEY HERE <---
  static const String _secretKey = 'sk_test_51TRFJqA8kPPvEpKagL3OM16itEl5yWWpvXbtumCTv3PoxnZWC07IFshLrdFgIgpdOdWhICBV2YDs0yHvRNw5PjVw00L5oJsguW';

  static Future<String?> createCheckoutSession(String airline, String price) async {
    final url = Uri.parse('https://api.stripe.com/v1/checkout/sessions');

    // Stripe expects amounts in cents (e.g., $46.52 -> 4652)
    final int amountInCents = (double.parse(price.replaceAll(',', '')) * 100).toInt();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'payment_method_types[]': 'card',
        'line_items[0][price_data][currency]': 'usd',
        'line_items[0][price_data][product_data][name]': 'Flight to $airline',
        'line_items[0][price_data][unit_amount]': amountInCents.toString(),
        'line_items[0][quantity]': '1',
        'mode': 'payment',
        // In a real app, these would be your real domain success/cancel pages
        'success_url': 'https://success.itinerary.app',
        'cancel_url': 'https://cancel.itinerary.app',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url']; // This is the live Stripe Checkout URL
    } else {
      print('Stripe Error: ${response.body}');
      return null;
    }
  }

  static Future<void> launchCheckout(String sessionUrl) async {
    final url = Uri.parse(sessionUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}