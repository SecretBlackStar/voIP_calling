import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth.services.dart';
import 'package:caller/utils/types.dart';
import 'package:flutter/material.dart';

class AirtimeService {
  final CollectionReference bundlesRef =
      FirebaseFirestore.instance.collection('airtimeBundles');

  Future<List<AirtimeBundle>> getAllAirtimeBundles() async {
    try {
      final querySnapshot = await bundlesRef.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AirtimeBundle(
          id: doc.id,
          name: data['name'] as String,
          price: (data['price'] as num).toDouble(),
          time: data['time'] as int,
        );
      }).toList();
    } catch (error) {
      print('Error fetching airtime bundles: $error');
      throw Exception('Failed to retrieve airtime bundles.');
    }
  }

  Future<AirtimeBundle> getOneAirtimeBundle(String id) async {
    try {
      final bundleDoc = bundlesRef.doc(id);
      final bundleSnapshot = await bundleDoc.get();

      if (!bundleSnapshot.exists) {
        throw Exception('Airtime bundle with ID $id not found.');
      }

      final data = bundleSnapshot.data() as Map<String, dynamic>;
      return AirtimeBundle(
        id: bundleSnapshot.id,
        name: data['name'] as String,
        price: (data['price'] as num).toDouble(),
        time: data['time'] as int,
      );
    } catch (error) {
      print('Error fetching airtime bundle: $error');
      throw Exception('Failed to retrieve airtime bundle.');
    }
  }

  Future<void> buyAirtimeStripe(BuildContext context, String bundleId) async {
    try {
      final bundle = await getOneAirtimeBundle(bundleId);
      final currentUser = await authService.getCurrentUser();
      final paymentIntent =
          await createPaymentIntent((bundle.price).toString(), 'USD');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Caller',
        ),
      );
      await displayPaymentSheet();
      final updatedAirtime = (currentUser?.airtime ?? 0) + bundle.time;
      await authService.updateUser({'airtime': updatedAirtime});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Your airtime has been updated.'),
          backgroundColor: Colors.green,
        ),
      );
      print('User airtime updated successfully.');
    } on StripeException catch (e) {
      if (e.error.message!.toLowerCase().contains('canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment was canceled.'),
            backgroundColor: Colors.orange,
          ),
        );
        print('Payment canceled by user.');
      } else {
        // Handle other Stripe-related errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e..error.message}'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error in buyAirtimeStripe: $e');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      print('Unexpected error in buyAirtimeStripe: $error');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      const url = 'https://api.stripe.com/v1/payment_intents';
      int parsedAmount = (double.parse(amount) * 100).toInt();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization':
              'Bearer sk_test_51QEWwyQ0hrJRXizcqlbosy86S92QOJ90DqkA7A1Gd6d1oo2Qdbj2iYyuCRye1CxorL6kmghXThgtvoGfnvWEk0D500xErLynFb',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': parsedAmount.toString(),
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode != 200) {
        print(response.body);
        throw Exception('Failed to create payment intent.');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      print('Error creating payment intent: $error');
      throw Exception('Failed to create payment intent.');
    }
  }

  Future<void> displayPaymentSheet() async {
      await Stripe.instance.presentPaymentSheet();
  }
}

final airtimeService = AirtimeService();
