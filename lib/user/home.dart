import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tkin/user/product.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<Map<String, dynamic>> _userData;
  String _searchQuery = "";
  late Future<List<Map<String, dynamic>>> _topRatedProducts;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
    _topRatedProducts = _fetchTopRatedProducts();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final displayName = data?['displayName'] ?? 'User';
        final profileImageUrl = data?['profileImageUrl'] ?? '';
        return {'displayName': displayName, 'profileImageUrl': profileImageUrl};
      }
    }
    return {'displayName': 'User', 'profileImageUrl': ''};
  }

  Future<double> _fetchAverageRating(String productName) async {
    final doc = await FirebaseFirestore.instance.collection('average_ratings').doc(productName).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['averageRating']?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> _fetchTopRatedProducts() async {
    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
    List<Map<String, dynamic>> products = [];
    for (var doc in productsSnapshot.docs) {
      String productName = doc['name'];
      double avgRating = await _fetchAverageRating(productName);
      products.add({
        'name': productName,
        'description': doc['description'],
        'imagePath': doc['imagePath'],
        'price': doc['price'].toDouble(),
        'quantity': doc['quantity'],
        'avgRating': avgRating
      });
    }
    products.sort((a, b) => b['avgRating'].compareTo(a['avgRating']));
    return products.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FutureBuilder(
            future: _userData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _userData = _fetchUserData();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.hasData) {
                return _buildHeader(snapshot.data!);
              }
              return const Center(child: Text('Welcome User', style: TextStyle(fontWeight: FontWeight.bold)));
            },
          ),
          _buildSearchBox(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _topRatedProducts = _fetchTopRatedProducts();
                });
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _topRatedProducts,
                    builder: (context, topRatedSnapshot) {
                      if (topRatedSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (topRatedSnapshot.hasError) {
                        return Center(child: Text('Error: ${topRatedSnapshot.error}'));
                      }
                      if (topRatedSnapshot.hasData && topRatedSnapshot.data!.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Top Rated',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildTopRatedTiles(topRatedSnapshot.data!),
                          ],
                        );
                      }
                      return Container(); // Or any other placeholder
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'All Products',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('products').snapshots(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No products available'));
                      }
                      final filteredProducts = snapshot.data!.docs.where((product) {
                        final name = product['name'].toString().toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();
                      filteredProducts.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          int quantity = product['quantity'] != null ? product['quantity'].toInt() : 0;
                          return FutureBuilder<double>(
                            future: _fetchAverageRating(product['name']),
                            builder: (context, ratingSnapshot) {
                              if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  //child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (ratingSnapshot.hasError) {
                                return Center(child: Text('Error: ${ratingSnapshot.error}'));
                              }
                              double avgRating = ratingSnapshot.data ?? 0.0;
                              return _buildMenuItem(
                                context,
                                product['name'],
                                product['description'],
                                product['imagePath'],
                                product['price'].toDouble(),
                                quantity,
                                avgRating,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> userData) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16.0),
      color: const Color(0xFF3D9F5E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Welcome ${userData['displayName']}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(userData['profileImageUrl']),
                  radius: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            hintText: 'Search products...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTopRatedTiles(List<Map<String, dynamic>> topRatedProducts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: topRatedProducts.map((product) {
            return GestureDetector(
              onTap: () {
                _onItemTap(
                  context,
                  product['name'],
                  product['description'],
                  product['imagePath'],
                  product['price'],
                  product['quantity'],
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      product['imagePath'],
                      height: 80.0,
                      width: 80.0,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(product['avgRating'].toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String name, String description, String imagePath, double price, int quantity, double avgRating) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: SizedBox(
        height: 120.0,
        child: Center(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 80.0,
                    maxHeight: 90.0,
                  ),
                  child: Center(
                    child: imagePath.startsWith('http')
                        ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text('Remaining: $quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(avgRating.toStringAsFixed(1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  onTap: () {
                    _onItemTap(context, name, description, imagePath, price, quantity);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, String name, String description, String imagePath, double price, int quantity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
          name: name,
          description: description,
          imagePath: imagePath,
          price: price,
          quantity: quantity,
        ),
      ),
    );
  }
}
