import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_bar_code/code/src/code_generate.dart';
import 'package:qr_bar_code/code/src/code_type.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchAndCopyOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchAndCopyOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final historyQuery = await FirebaseFirestore.instance
          .collection('history')
          .where('userId', isEqualTo: user.uid)
          .where('transactionStatus', isEqualTo: 'Successful')
          .where('scanned', isEqualTo: 'not scanned')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> filteredOrders = historyQuery.docs.map((doc) {
        var data = doc.data();
        data['orderId'] = doc.id; // Add the document ID to the data map
        data.remove('scanned'); // Remove the 'scanned' field
        return data;
      }).toList();

      // Copy filtered orders to the new orders collection
      for (var order in filteredOrders) {
        // Check if the order already exists in the orders collection
        final existingOrder = await FirebaseFirestore.instance
            .collection('orders')
            .doc(order['orderId'])
            .get();

        if (!existingOrder.exists) {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(order['orderId'])
              .set(order);
        }
      }

      return filteredOrders;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();
      return ordersQuery.docs.map((doc) {
        var data = doc.data();
        data['orderId'] = doc.id; // Add the document ID to the data map
        return data;
      }).toList();
    }
    return [];
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  void _showQrCode(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            width: 300, // Set your desired width
            height: 300, // Set your desired height
            child: Center(
              child: Code(data: orderId, codeType: CodeType.qrCode()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _refreshOrders(); // Refresh orders when the QR code dialog is closed
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    ).then((_) {
      _refreshOrders(); // Refresh orders when the dialog is dismissed by back button
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                List<dynamic> items = order['orderedProducts'] ?? [];
                double totalPrice = order['totalPrice'] ?? 0.0;
                String transactionStatus = order['transactionStatus'] ?? 'Unknown';
                String orderId = order['orderId'] ?? 'Unknown';
                Timestamp timestamp = order['timestamp'] ?? Timestamp.now();

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text('Order ID: $orderId')),
                            if (transactionStatus != 'Failed')
                              IconButton(
                                icon: Icon(Icons.qr_code),
                                onPressed: () {
                                  _showQrCode(context, orderId);
                                },
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var item in items)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Product: ${item['name'] ?? 'Unknown'}'),
                                  Text('Price: ₹${item['price'] ?? 0}'),
                                  Text('Quantity: ${item['quantity'] ?? 0}'),
                                ],
                              ),
                            const SizedBox(height: 10), // Custom space before total price
                            Text('Total Price: ₹$totalPrice', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Transaction Status: $transactionStatus', style: TextStyle(color: Colors.blue)), // Display order status
                            Text(
                              'Ordered on ${timestamp.toDate().toString()}',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
