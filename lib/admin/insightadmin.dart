import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsightScreen extends StatefulWidget {
  @override
  _InsightScreenState createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  DateTime? _selectedDate;
  String _selectedMonth = '';
  String _selectedYear = '';
  String _selectedFilter = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Filter Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Select Date',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                          _selectedFilter = 'None';
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                          : '',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Month',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMonth,
                    items: [
                      '',
                      'January',
                      'February',
                      'March',
                      'April',
                      'May',
                      'June',
                      'July',
                      'August',
                      'September',
                      'October',
                      'November',
                      'December'
                    ]
                        .map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                        _selectedFilter = 'None';
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Year',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        _selectedFilter = 'None';
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Today'),
                    value: 'Today',
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                        _selectedDate = null;
                        _selectedMonth = '';
                        _selectedYear = '';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Yesterday'),
                    value: 'Yesterday',
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                        _selectedDate = null;
                        _selectedMonth = '';
                        _selectedYear = '';
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Order Insights',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('history').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var orders = snapshot.data!.docs;

                  var filteredOrders = orders.where((order) {
                    if (order['transactionStatus'] != 'Successful') {
                      return false;
                    }

                    DateTime orderDate = (order['timestamp'] as Timestamp).toDate();

                    bool matchesDate = _selectedDate != null
                        ? orderDate.day == _selectedDate!.day &&
                        orderDate.month == _selectedDate!.month &&
                        orderDate.year == _selectedDate!.year
                        : true;
                    bool matchesMonth = _selectedMonth.isNotEmpty
                        ? orderDate.month == _monthToInt(_selectedMonth)
                        : true;
                    bool matchesYear = _selectedYear.isNotEmpty
                        ? orderDate.year == int.parse(_selectedYear)
                        : true;
                    bool matchesToday = _selectedFilter == 'Today'
                        ? _isSameDate(orderDate, DateTime.now())
                        : true;
                    bool matchesYesterday = _selectedFilter == 'Yesterday'
                        ? _isSameDate(orderDate, DateTime.now().subtract(Duration(days: 1)))
                        : true;

                    return matchesDate &&
                        matchesMonth &&
                        matchesYear &&
                        matchesToday &&
                        matchesYesterday;
                  }).toList();

                  Map<String, int> productCounts = {};
                  Map<String, double> productTotals = {};
                  double totalFilteredAmount = 0.0;

                  for (var order in filteredOrders) {
                    for (var item in order['orderedProducts']) {
                      String productName = item['name'];
                      int quantity = item['quantity'];
                      double price = item['price'].toDouble();

                      if (!productCounts.containsKey(productName)) {
                        productCounts[productName] = 0;
                        productTotals[productName] = 0.0;
                      }

                      productCounts[productName] = productCounts[productName]! + quantity;
                      productTotals[productName] = productTotals[productName]! + (quantity * price);
                      totalFilteredAmount += (quantity * price);
                    }
                  }

                  if (productCounts.isEmpty) {
                    return Center(child: Text('No orders found for the selected date.'));
                  }

                  return Column(
                    children: [
                      Text(
                        'Total Amount: ₹$totalFilteredAmount',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: productCounts.keys.length,
                          itemBuilder: (context, index) {
                            String productName = productCounts.keys.elementAt(index);
                            int quantity = productCounts[productName]!;
                            double total = productTotals[productName]!;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: ListTile(
                                title: Text(
                                  productName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Total Purchased: $quantity\nTotal Amount: ₹$total'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdditionalInfo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.info),
      ),
    );
  }

  int _monthToInt(String month) {
    switch (month) {
      case 'January':
        return 1;
      case 'February':
        return 2;
      case 'March':
        return 3;
      case 'April':
        return 4;
      case 'May':
        return 5;
      case 'June':
        return 6;
      case 'July':
        return 7;
      case 'August':
        return 8;
      case 'September':
        return 9;
      case 'October':
        return 10;
      case 'November':
        return 11;
      case 'December':
        return 12;
      default:
        return 0;
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showAdditionalInfo() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('transactionStatus', isEqualTo: 'Successful')
        .where('scanned', isEqualTo: 'not scanned')
        .get();

    var orders = snapshot.docs;

    var filteredOrders = orders.where((order) {
      DateTime orderDate = (order['timestamp'] as Timestamp).toDate();

      bool matchesDate = _selectedDate != null
          ? orderDate.day == _selectedDate!.day &&
          orderDate.month == _selectedDate!.month &&
          orderDate.year == _selectedDate!.year
          : true;
      bool matchesMonth = _selectedMonth.isNotEmpty
          ? orderDate.month == _monthToInt(_selectedMonth)
          : true;
      bool matchesYear = _selectedYear.isNotEmpty
          ? orderDate.year == int.parse(_selectedYear)
          : true;
      bool matchesToday = _selectedFilter == 'Today'
          ? _isSameDate(orderDate, DateTime.now())
          : true;
      bool matchesYesterday = _selectedFilter == 'Yesterday'
          ? _isSameDate(orderDate, DateTime.now().subtract(Duration(days: 1)))
          : true;

      return matchesDate &&
          matchesMonth &&
          matchesYear &&
          matchesToday &&
          matchesYesterday;
    }).toList();

    double totalAmount = 0.0;

    for (var order in filteredOrders) {
      for (var item in order['orderedProducts']) {
        int quantity = item['quantity'];
        double price = item['price'].toDouble();
        totalAmount += quantity * price;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Additional Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total orders not scanned: ${filteredOrders.length}'),
            SizedBox(height: 10),
            Text('Total Amount: ₹$totalAmount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
