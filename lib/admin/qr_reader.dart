import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRReader extends StatefulWidget {
  @override
  _QRReaderState createState() => _QRReaderState();
}

class _QRReaderState extends State<QRReader> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFetching = false;
  bool isFlashOn = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isFetching && scanData.code != null) {
        setState(() {
          isFetching = true;
        });
        await _fetchOrderDetails(scanData.code!);
      }
    });
  }

  Future<void> _fetchOrderDetails(String orderId) async {
    try {
      final order = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (order.exists) {
        final user = await FirebaseFirestore.instance
            .collection('users')
            .doc(order.data()!['userId'])
            .get();

        setState(() {
          isFetching = false;
        });
        controller?.pauseCamera();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              orderId: orderId, // Pass the orderId to OrderDetailsScreen
              orderDetails: order.data()!,
              displayName: user.data()!['displayName'],
              onScanAnother: _restartQRScanner,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order not found')),
        );
        setState(() {
          isFetching = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch order details. Scan a valid code')),
      );
      setState(() {
        isFetching = false;
      });
    }
  }

  void _restartQRScanner() {
    setState(() {
      isFetching = false;
    });
    controller?.resumeCamera();
  }

  void _toggleFlash() {
    if (controller != null) {
      controller!.toggleFlash();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  Future<void> _refreshNetwork() async {
    // Implement your network refresh logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Reader'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNetwork,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Center(
                    child: Text('Scan a code',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            if (isFetching)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderDetails;
  final String displayName;
  final VoidCallback onScanAnother;

  OrderDetailsScreen({
    required this.orderId, // Added orderId as a parameter
    required this.orderDetails,
    required this.displayName,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> orderedProducts = orderDetails['orderedProducts'];
    final double totalPrice = orderDetails['totalPrice'];

    return WillPopScope(
      onWillPop: () async {
        onScanAnother();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Details for $displayName'),
          backgroundColor: Colors.green,
        ),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text(
                    'Transaction Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(orderDetails['transactionStatus'].toString()),
                ),
                ListTile(
                  leading: Icon(Icons.confirmation_number),
                  title: const Text(
                    'Transaction ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(orderDetails['transactionId'].toString()),
                ),
                const ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text(
                    'Ordered Products',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...orderedProducts.map((product) => ListTile(
                  leading: Icon(Icons.label),
                  title: Text(
                    'Product Name: ${product['name']}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  subtitle: Text(
                    'Quantity: ${product['quantity'].toString()}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )),
                ListTile(
                  leading: Icon(Icons.receipt),
                  title: const Text(
                    'Total Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('₹${totalPrice.toStringAsFixed(2)}'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _addOrderToHistory(orderDetails['userId'], orderId); // Pass userId and orderId to the method
                    onScanAnother();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            onScanAnother();
            Navigator.pop(context);
          },
          child: Icon(Icons.qr_code_scanner),
          tooltip: 'Scan Another',
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  Future<void> _addOrderToHistory(String userId, String orderId) async {
    try {
      // Update the 'scanned' field in the history collection
      final historyQuery = await FirebaseFirestore.instance
          .collection('history')
          .where('userId', isEqualTo: userId)
          .where('orderId', isEqualTo: orderId) // Ensure you filter by orderId as well
          .get();

      if (historyQuery.docs.isNotEmpty) {
        final historyDocId = historyQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection('history')
            .doc(historyDocId)
            .update({'scanned': 'Yes'});
      }

      // Remove the order from the orders collection
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error updating order in history or deleting from orders: $e');
    }
  }
}
