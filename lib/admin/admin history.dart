import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHistoryScreen extends StatefulWidget {
  @override
  _AdminHistoryScreenState createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  List<Map<String, dynamic>> _historyList = [];
  List<Map<String, dynamic>> _filteredHistoryList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final historySnapshot = await FirebaseFirestore.instance.collection('history').get();
      List<Map<String, dynamic>> historyList = [];

      for (var doc in historySnapshot.docs) {
        Map<String, dynamic> historyData = doc.data();
        String userId = historyData['userId'] ?? 'Unknown User';
        String transactionId = historyData['transactionId'] ?? 'NULL';

        // Fetch user display name
        final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        String displayName = userSnapshot.data()?['displayName'] ?? 'Unknown User';

        historyData['displayName'] = displayName;
        historyData['transactionId'] = transactionId;
        historyList.add(historyData);
      }

      setState(() {
        _historyList = historyList;
        _filteredHistoryList = historyList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterHistory(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredHistoryList = _historyList;
      });
    } else {
      setState(() {
        _filteredHistoryList = _historyList.where((history) {
          return history['displayName'].toLowerCase().contains(query.toLowerCase()) ||
              history['transactionId'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History (Admin)'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Display Name or Transaction ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _filterHistory(query);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredHistoryList.length,
              itemBuilder: (context, index) {
                final history = _filteredHistoryList[index];
                List<dynamic> items = history['orderedProducts'] ?? [];
                double totalPrice = history['totalPrice']?.toDouble() ?? 0.0;
                String transactionStatus = history['transactionStatus'] ?? 'Unknown';
                Timestamp timestamp = history['timestamp'] ?? Timestamp.now();
                DateTime orderDate = timestamp.toDate();
                String scanned = history['scanned'] ?? 'Unknown';

                // Determine card color based on transaction status
                Color cardColor = transactionStatus.toLowerCase() == 'failed'
                    ? Colors.redAccent
                    : Colors.greenAccent;

                // Determine text color based on scanned status
                Color scannedColor = scanned.toLowerCase() == 'not scanned'
                    ? Colors.red
                    : Colors.green[700]!;

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('User: ${history['displayName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaction ID: ${history['transactionId']}'),
                        for (var item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Product: ${item['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Price: ₹${item['price'] ?? 0}'),
                                Text('Quantity: ${item['quantity'] ?? 0}', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text('Total Price: ₹$totalPrice', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Transaction Status: $transactionStatus', style: const TextStyle(fontSize: 14)),
                        Text('Scanned Status: $scanned', style: TextStyle(color: scannedColor)),
                        Text('Ordered on ${orderDate.toString()}', style: const TextStyle(fontSize: 12.0)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
