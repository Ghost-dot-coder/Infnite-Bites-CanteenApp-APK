import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tkin/user/payment.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cartData;
  bool _canCheckout = true;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userCartDoc = FirebaseFirestore.instance.collection('user_carts').doc(user.uid);
      final docSnapshot = await userCartDoc.get();
      if (docSnapshot.exists) {
        setState(() {
          _cartData = docSnapshot.data();
          _checkCanCheckout();
        });
      } else {
        setState(() {
          _cartData = null;
        });
      }
    }
  }

  void _removeFromCart(int index) {
    if (_cartData != null) {
      List<dynamic> items = _cartData?['items'] ?? [];
      int currentQuantity = items[index]['quantity'] as int;
      if (currentQuantity > 1) {
        items[index]['quantity'] = currentQuantity - 1;
      } else {
        items.removeAt(index);
      }
      _updateCartData(items);
      _checkCanCheckout();
    }
  }

  void _addToCart(int index) async {
    if (_cartData != null) {
      List<dynamic> items = _cartData?['items'] ?? [];
      final item = items[index];
      final productQuerySnapshot = await FirebaseFirestore.instance.collection('products').where('name', isEqualTo: item['name']).limit(1).get();
      if (productQuerySnapshot.docs.isNotEmpty) {
        final productData = productQuerySnapshot.docs.first.data();
        int availableQuantity = productData['quantity'] as int;
        int currentQuantity = item['quantity'] as int;
        if (currentQuantity < availableQuantity) {
          items[index]['quantity'] = currentQuantity + 1;
          _updateCartData(items);
          _checkCanCheckout();
        }
      }
    }
  }

  void _removeAllFromCart(int index) {
    if (_cartData != null) {
      List<dynamic> items = _cartData?['items'] ?? [];
      items.removeAt(index);
      _updateCartData(items);
      _checkCanCheckout();
    }
  }

  void _updateCartData(List<dynamic> items) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userCartDoc = FirebaseFirestore.instance.collection('user_carts').doc(user.uid);
      double totalPrice = _calculateTotalPrice(items);
      userCartDoc.update({'items': items, 'totalPrice': totalPrice});
      setState(() {
        _cartData = {'items': items, 'totalPrice': totalPrice};
      });
    }
  }

  Future<void> _checkCanCheckout() async {
    bool canCheckout = true;
    if (_cartData != null) {
      List<dynamic> items = _cartData?['items'] ?? [];
      for (final item in items) {
        final productQuerySnapshot = await FirebaseFirestore.instance.collection('products').where('name', isEqualTo: item['name']).limit(1).get();
        if (productQuerySnapshot.docs.isNotEmpty) {
          final productData = productQuerySnapshot.docs.first.data();
          if (productData['quantity'] < item['quantity']) {
            canCheckout = false;
            break;
          }
        }
      }
    }
    setState(() {
      _canCheckout = canCheckout;
    });
  }

  double _calculateTotalPrice(List<dynamic> items) {
    double totalPrice = 0.0;
    for (final item in items) {
      totalPrice += (item['price'] as double) * (item['quantity'] as int);
    }
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: _cartData == null || (_cartData?['items'] as List<dynamic>).isEmpty
          ? const Center(
        child: Text('Your cart is empty'),
      )
          : ListView.separated(
        itemCount: (_cartData?['items'] as List<dynamic>).length,
        itemBuilder: (context, index) {
          final item = (_cartData?['items'] as List<dynamic>)[index];
          return ListTile(
            title: Text('${item['name']} - \₹${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
            subtitle: Text('Quantity: ${item['quantity']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    _addToCart(index);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    _removeFromCart(index);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _removeAllFromCart(index);
                  },
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: ElevatedButton(
          onPressed: (_canCheckout &&
              _cartData != null &&
              _cartData?['items'] != null &&
              (_cartData?['items'] as List<dynamic>).isNotEmpty)
              ? () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(totalPrice: _cartData?['totalPrice'] ?? 0.0),
              ),
            );
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen, // Set the background color to red
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: \₹${_cartData?['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
