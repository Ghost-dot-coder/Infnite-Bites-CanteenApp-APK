import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'homescreen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;

  PaymentScreen({required this.totalPrice});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _processingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: _processingPayment
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please confirm the payment of amount: ₹${widget.totalPrice.toStringAsFixed(2)}\n ',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _processPayment(context);
              },
              child: Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    setState(() {
      _processingPayment = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var options = {
        'key': 'rzp_test_ErUeptYtsuJuxi',
        'amount': (widget.totalPrice * 100).toInt(),
        'name': 'Infinite Bites',
        'description': 'Payment for some product',
        'prefill': {'contact': '9447706386', 'email': 'manubabychan02@gmail.com'},
        'payment_method_types': ['upi', 'card', 'netbanking', 'wallet']
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      print('User is not authenticated');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final userCartDoc = await FirebaseFirestore.instance.collection('user_carts').doc(userId).get();
    final cartItems = userCartDoc.data()?['items'] ?? [];

    final productsCollection = FirebaseFirestore.instance.collection('products');
    for (final item in cartItems) {
      final productQuerySnapshot = await productsCollection.where('name', isEqualTo: item['name']).limit(1).get();
      if (productQuerySnapshot.docs.isNotEmpty) {
        final productData = productQuerySnapshot.docs.first.data();
        final newQuantity = productData['quantity'] - (item['quantity'] as int);
        if (newQuantity >= 0) {
          await productsCollection.doc(productQuerySnapshot.docs.first.id).update({'quantity': newQuantity});
        } else {
          // Show an error dialogue if the remaining quantity is 0
          return;
        }
      }
    }

    // Add a new document to the 'history' collection and get its reference
    final historyDocRef = await FirebaseFirestore.instance.collection('history').add({
      'userId': userId,
      'transactionId': response.paymentId,
      'transactionStatus': 'Successful',
      'orderedProducts': cartItems,
      'totalPrice': widget.totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'scanned': 'not scanned',  // New field added here
    });

    // Get the document ID to use as the order ID
    final orderId = historyDocRef.id;

    // Update the document with the order ID
    await historyDocRef.update({'orderId': orderId});

    // Clear the cart after successful payment
    _clearCart(context, userId);
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage(selectedIndex: 2)));
  }

  void _clearCart(BuildContext context, String userId) async {
    final userCartDoc = FirebaseFirestore.instance.collection('user_carts').doc(userId);

    await userCartDoc.update({'items': [], 'totalPrice': 0.0});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful. Cart cleared.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Get the ordered products from the user's cart
    final userCartDoc = await FirebaseFirestore.instance.collection('user_carts').doc(userId).get();
    final cartItems = userCartDoc.data()?['items'] ?? [];

    // Create an order document in the 'history' collection with the payment failure status
    final historyDocRef = await FirebaseFirestore.instance.collection('history').add({
      'userId': userId,
      'transactionStatus': 'Failed',
      'orderedProducts': cartItems,
      'totalPrice': widget.totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'scanned': 'not scanned',  // New field added here
    });

    // Get the document ID to use as the order ID
    final orderId = historyDocRef.id;

    // Update the document with the order ID
    await historyDocRef.update({'orderId': orderId});
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage(selectedIndex: 1)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment failed. Please try again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet response
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }
}
