import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homescreen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final String imagePath;
  final double price;
  final int quantity;

  ItemDetailScreen({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.price,
    required this.quantity,
  });

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _selectedQuantity = 1;
  bool _isLoading = false;
  double _averageRating = 0;
  int _totalRatings = 0;
  int? _userRating;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _fetchProductId();
  }

  Future<void> _fetchProductId() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isEqualTo: widget.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _productId = querySnapshot.docs.first.id;
        _fetchRatingInfo();
        _fetchUserRating();
      });
    } else {
      print('Product not found in Firestore');
    }
  }

  Future<void> _fetchRatingInfo() async {
    if (_productId == null) return;

    final productDoc = FirebaseFirestore.instance.collection('products').doc(_productId);
    final docSnapshot = await productDoc.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      setState(() {
        _averageRating = data?['averageRating']?.toDouble() ?? 0;
        _totalRatings = data?['totalRatings'] ?? 0;
      });
    }
  }

  Future<void> _fetchUserRating() async {
    if (_productId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ratingDoc = FirebaseFirestore.instance
          .collection('user_ratings')
          .doc(user.uid)
          .collection('ratings')
          .doc(_productId);
      final docSnapshot = await ratingDoc.get();
      if (docSnapshot.exists) {
        setState(() {
          _userRating = docSnapshot.data()?['rating'];
        });
      }
    }
  }

  void _rateProduct(int rating) async {
    if (_productId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRatingDoc = FirebaseFirestore.instance
          .collection('user_ratings')
          .doc(user.uid)
          .collection('ratings')
          .doc(_productId);
      final productDoc = FirebaseFirestore.instance.collection('products').doc(_productId);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnapshot = await transaction.get(productDoc);
        final ratingSnapshot = await transaction.get(userRatingDoc);

        int totalRatings = productSnapshot.data()?['totalRatings'] ?? 0;
        double averageRating = productSnapshot.data()?['averageRating']?.toDouble() ?? 0;

        if (ratingSnapshot.exists) {
          int oldRating = ratingSnapshot.data()?['rating'];
          double newAverage = ((averageRating * totalRatings) - oldRating + rating) / totalRatings;
          transaction.update(userRatingDoc, {'rating': rating});
          transaction.update(productDoc, {'averageRating': newAverage});
          setState(() {
            _averageRating = newAverage;
            _userRating = rating;
          });
        } else {
          double newAverage = ((averageRating * totalRatings) + rating) / (totalRatings + 1);
          transaction.set(userRatingDoc, {'rating': rating});
          transaction.update(productDoc, {
            'averageRating': newAverage,
            'totalRatings': totalRatings + 1,
          });
          setState(() {
            _averageRating = newAverage;
            _totalRatings++;
            _userRating = rating;
          });
        }
      });
    } else {
      print('User is not authenticated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: TextEditingController(),
              openCart: false,
            ),
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  child: widget.imagePath.startsWith('http')
                      ? Image.network(
                    widget.imagePath,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    widget.imagePath,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 20.0),
                Text(
                  '₹${(widget.price * _selectedQuantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedQuantity > 1) {
                            _selectedQuantity--;
                          }
                        });
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(width: 16.0),
                    Text('Quantity: $_selectedQuantity'),
                    SizedBox(width: 16.0),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedQuantity < widget.quantity) {
                            _selectedQuantity++;
                          }
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Average Rating: ${_averageRating.toStringAsFixed(1)} / 5',
                  style: const TextStyle(fontSize: 18.0),
                ),
                Text(
                  'Total Ratings: $_totalRatings',
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        _rateProduct(index + 1);
                      },
                      icon: Icon(
                        Icons.star,
                        color: (index < (_userRating ?? 0)) ? Colors.yellow : Colors.grey,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 80.0), // Space to push buttons to the bottom
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _addToCart(context, _selectedQuantity);
                  },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : const Text('Add to Cart', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          username: TextEditingController(),
                          openCart: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to Cart', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, int quantity) async {
    if (quantity <= 0 || _productId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userCartDoc = FirebaseFirestore.instance.collection('user_carts').doc(user.uid);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(userCartDoc);

        if (docSnapshot.exists) {
          List<dynamic> items = docSnapshot.data()?['items'] ?? [];
          int existingItemIndex = items.indexWhere((item) => item['name'] == widget.name);

          if (existingItemIndex != -1) {
            int currentQuantity = items[existingItemIndex]['quantity'] as int;
            if (currentQuantity + quantity <= widget.quantity) {
              items[existingItemIndex]['quantity'] = currentQuantity + quantity;
              items[existingItemIndex]['total'] =
                  (items[existingItemIndex]['price'] as double) * (currentQuantity + quantity);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Only ${widget.quantity - currentQuantity} ${widget.name} available'),
                  duration: Duration(seconds: 2),
                ),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          } else {
            if (quantity <= widget.quantity) {
              items.add({
                'name': widget.name,
                'price': widget.price,
                'quantity': quantity,
                'total': widget.price * quantity
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Only ${widget.quantity} ${widget.name} available'),
                  duration: Duration(seconds: 2),
                ),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }

          transaction.update(userCartDoc, {'items': items});

          double totalPrice = items.fold(0, (total, item) => total + (item['total'] as double));
          transaction.update(userCartDoc, {'totalPrice': totalPrice});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedQuantity} ${widget.name} added to cart'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          if (quantity <= widget.quantity) {
            transaction.set(
              userCartDoc,
              {
                'items': [
                  {
                    'name': widget.name,
                    'price': widget.price,
                    'quantity': quantity,
                    'total': widget.price * quantity
                  }
                ],
                'totalPrice': widget.price * quantity,
              },
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_selectedQuantity} ${widget.name} added to cart'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Only ${widget.quantity} ${widget.name} available, check again later'),
                duration: Duration(seconds: 3),
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      print('User is not authenticated');
      setState(() {
        _isLoading = false;
      });
    }
  }
}
