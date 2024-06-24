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
  int _selectedRating = 0;
  Map<String, int> _ratingCounts = {
    '1': 0,
    '2': 0,
    '3': 0,
    '4': 0,
    '5': 0,
  };
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  void _loadRatings() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('item_ratings')
          .doc(widget.name)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _ratingCounts = {
            '1': data['1'] ?? 0,
            '2': data['2'] ?? 0,
            '3': data['3'] ?? 0,
            '4': data['4'] ?? 0,
            '5': data['5'] ?? 0,
          };
          _calculateAverageRating();
        });
      }
    } catch (e) {
      print('Error loading ratings: $e');
    }
  }

  void _calculateAverageRating() {
    int totalRatings = _ratingCounts.values.reduce((a, b) => a + b);
    int totalPoints = _ratingCounts.entries
        .map((e) => int.parse(e.key) * e.value)
        .reduce((a, b) => a + b);
    setState(() {
      _averageRating = totalRatings > 0 ? totalPoints / totalRatings : 0.0;
    });
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
                _buildRatingStars(),
                Text(
                  'Average Rating: ${_averageRating.toStringAsFixed(1)} (${_ratingCounts.values.reduce((a, b) => a + b)} ratings)',
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    _rateProduct(context, _selectedRating);
                  },
                  child: const Text('Rate Product', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _selectedRating = index + 1;
            });
          },
        );
      }),
    );
  }

  void _addToCart(BuildContext context, int quantity) async {
    if (quantity <= 0) {
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

  void _rateProduct(BuildContext context, int rating) async {
    if (rating < 1 || rating > 5) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final itemRatingDoc = FirebaseFirestore.instance.collection('item_ratings').doc(widget.name);
      final userRatingDoc = FirebaseFirestore.instance.collection('user_ratings').doc('${user.uid}_${widget.name}');
      final avgRatingDoc = FirebaseFirestore.instance.collection('average_ratings').doc(widget.name);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRatingSnapshot = await transaction.get(userRatingDoc);
        int previousRating = 0;

        if (userRatingSnapshot.exists) {
          previousRating = userRatingSnapshot.data()?['rating'] ?? 0;
        }

        final itemRatingSnapshot = await transaction.get(itemRatingDoc);

        if (itemRatingSnapshot.exists) {
          Map<String, dynamic> data = itemRatingSnapshot.data() as Map<String, dynamic>;

          if (previousRating != 0) {
            data[previousRating.toString()] = (data[previousRating.toString()] ?? 1) - 1;
          }

          data[rating.toString()] = (data[rating.toString()] ?? 0) + 1;
          transaction.update(itemRatingDoc, data);
        } else {
          transaction.set(
            itemRatingDoc,
            {
              '1': rating == 1 ? 1 : 0,
              '2': rating == 2 ? 1 : 0,
              '3': rating == 3 ? 1 : 0,
              '4': rating == 4 ? 1 : 0,
              '5': rating == 5 ? 1 : 0,
            },
          );
        }

        transaction.set(
          userRatingDoc,
          {
            'rating': rating,
          },
        );

        // Update the rating counts and calculate the new average rating
        setState(() {
          if (previousRating != 0) {
            _ratingCounts[previousRating.toString()] = (_ratingCounts[previousRating.toString()] ?? 1) - 1;
          }
          _ratingCounts[rating.toString()] = (_ratingCounts[rating.toString()] ?? 0) + 1;
          _calculateAverageRating();
        });

        // Save the average rating in the new average_ratings collection
        transaction.set(avgRatingDoc, {
          'averageRating': _averageRating,
          'totalRatings': _ratingCounts.values.reduce((a, b) => a + b),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanks for rating!'),
            duration: Duration(seconds: 2),
          ),
        );
      }).then((_) {
        print('Rating transaction successful');
      }).catchError((error) {
        print('Rating transaction failed: $error');
      });
    } else {
      print('User is not authenticated');
    }
  }
}
