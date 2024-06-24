import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<DocumentSnapshot>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<DocumentSnapshot>> _fetchOrders() async {
    try {
      final ordersQuery = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();
      final querySnapshot = await ordersQuery;
      return querySnapshot.docs;
    } catch (e) {
      // Handle the error as needed
      print("Error fetching orders: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      // Handle the error as needed
      print("Error fetching user: $e");
    }
    return null;
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order List (Admin)'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<DocumentSnapshot>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return const Center(child: Text('No orders found.'));
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                List<dynamic> items = order['orderedProducts'];
                double totalPrice = order['totalPrice'];
                String transactionStatus = order['transactionStatus'];
                Timestamp timestamp = order['timestamp'];
                DateTime orderDate = timestamp.toDate();
                String userId = order['userId']; // Assuming each order has a userId field

                // Determine card color based on transaction status
                Color cardColor;
                if (transactionStatus.toLowerCase() == 'failed') {
                  cardColor = Colors.redAccent;
                } else {
                  cardColor = Colors.greenAccent;
                }

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUser(userId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    String displayName = 'Unknown User';
                    if (userSnapshot.hasData) {
                      displayName = userSnapshot.data?['displayName'] ?? 'Unknown User';
                    }

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Order ID: ${orders[index].id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User: $displayName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                for (var item in items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Product: ${item['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('Price: ₹${item['price']}'),
                                        Text('Quantity: ${item['quantity']}', style: const TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Text('Total Price: ₹$totalPrice', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Transaction Status: $transactionStatus', style: const TextStyle(fontSize: 14)),
                                Text('Ordered on ${orderDate.toString()}', style: const TextStyle(fontSize: 12.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
