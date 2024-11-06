import 'package:flutter/material.dart';
import 'package:caller/services/airtime.services.dart';
import 'package:caller/utils/types.dart';

class AirtimePurchasePage extends StatefulWidget {
  @override
  _AirtimePurchasePageState createState() => _AirtimePurchasePageState();
}

class _AirtimePurchasePageState extends State<AirtimePurchasePage> {
  List<AirtimeBundle> bundles = [];
  bool loading = true;
  String? error;
  Map<String, bool> loadingStripeButtons =
      {}; // Track loading state for Stripe button per item

  @override
  void initState() {
    super.initState();
    fetchAirtimeBundles();
  }

  Future<void> fetchAirtimeBundles() async {
    setState(() {
      loading = true;
    });

    try {
      final fetchedBundles = await airtimeService.getAllAirtimeBundles();
      setState(() {
        bundles = fetchedBundles;
        error = null; // Clear any previous errors
      });
    } catch (err) {
      setState(() {
        error = err.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String formatDuration(int duration) {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Widget renderAirtimeItem(AirtimeBundle item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (item.description != null) ...[
            SizedBox(height: 8),
            Text(item.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
          SizedBox(height: 12),
          Text(
              'Duration: ${formatDuration(item.time)} | Price: \$${item.price.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.black54)),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: loadingStripeButtons[item.id] == true
                    ? null
                    : () async {
                        setState(() {
                          loadingStripeButtons[item.id] = true;
                        });
                        try {
                          await airtimeService.buyAirtimeStripe(
                              context, item.id);
                          if (mounted) {
                            Navigator.pushNamed(context, '/home');
                          }
                        } catch (e) {
                          print("Error buying airtime with Stripe: $e");
                        } finally {
                          setState(() {
                            loadingStripeButtons[item.id] = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB05AAD),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                icon: loadingStripeButtons[item.id] == true
                    ? CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      )
                    : Icon(Icons.credit_card, color: Colors.white),
                label: Text(
                  loadingStripeButtons[item.id] == true
                      ? 'Processing...'
                      : 'Buy with Stripe',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle cryptocurrency purchase here
                  // e.g., show a dialog or navigate to a new page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color(0xFF4CAF50), // A different color for crypto button
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                icon: Icon(Icons.currency_bitcoin, color: Colors.white),
                label: Text('Buy with Crypto',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Get Airtime', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? LoadingSkeleton()
            : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: bundles.length,
                    itemBuilder: (context, index) {
                      return renderAirtimeItem(bundles[index]);
                    },
                  ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(bottom: 16),
        );
      }),
    );
  }
}
