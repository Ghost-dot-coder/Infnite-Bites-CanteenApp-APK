import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<DocumentSnapshot>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<DocumentSnapshot>> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final historyQuery = FirebaseFirestore.instance
          .collection('history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();
      final querySnapshot = await historyQuery;
      return querySnapshot.docs;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(child: Text('No history available.'));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final order = history[index].data() as Map<String, dynamic>;
              List<dynamic> items = order['orderedProducts'] as List<dynamic>;
              double totalPrice = order['totalPrice'] as double;
              String transactionStatus = order['transactionStatus'] as String;
              String? transactionId = order['transactionId'] as String?;
              String scanned = order['scanned'] as String;
              String orderId = history[index].id;

              // Determine card color based on transaction status
              Color cardColor = transactionStatus.toLowerCase() == 'failed'
                  ? Colors.redAccent
                  : Colors.greenAccent;

              // Determine text color based on scanned status
              Color scannedColor = scanned.toLowerCase() == 'not scanned'
                  ? Colors.red
                  : Colors.green[700]!;

              // If transaction fails, set transactionId to null
              if (transactionStatus.toLowerCase() == 'failed') {
                transactionId = null;
              }

              return Card(
                color: cardColor,
                margin: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text('Order ID: $orderId'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var item in items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Product: ${item['name']}'),
                                  Text('Price: ₹${item['price']}'),
                                  Text('Quantity: ${item['quantity']}'),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10), // Custom space before total price
                          Text('Total Price: ₹$totalPrice'),
                          Text('Transaction Status: $transactionStatus'),
                          Text('Transaction ID: ${transactionId ?? 'N/A'}'),
                          Text('Scanned Status: $scanned', style: TextStyle(color: scannedColor)),
                          if (transactionStatus.toLowerCase() == 'successful')
                            Text(
                              'Ordered on ${order['timestamp'].toDate().toString()}',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
