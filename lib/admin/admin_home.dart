import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_editproduct.dart';
import 'insightadmin.dart';
import 'new_item.dart';

class AdminHomeTab extends StatefulWidget {
  @override
  _AdminHomeTabState createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
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

            return ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                int quantity = product['quantity'] != null ? product['quantity'].toInt() : 0;
                return _buildMenuItem(
                  context,
                  product.id,  // Pass product ID for editing and deleting
                  product['name'],
                  product['description'],
                  product['imagePath'],
                  product['price'].toDouble(),
                  quantity,
                );
              },
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'insights',
            onPressed: _showInsights,
            child: Icon(Icons.insights),
            backgroundColor: Colors.blue, // Optional: color for the insights button
          ),
          SizedBox(height: 10), // Space between buttons
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addNewProduct,
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String id, String name, String description, String imagePath, double price, int quantity) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10.0),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text('Remaining: $quantity', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Text('\₹$price', style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: Container(
          width: 80.0,
          height: 80.0,
          child: imagePath.startsWith('http')
              ? Image.network(imagePath, fit: BoxFit.cover)
              : Image.asset(imagePath, fit: BoxFit.cover),
        ),
        onTap: () {
          _showItemActions(context, id, name, description, imagePath, price, quantity);
        },
      ),
    );
  }

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewitemTab(),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _editProduct(BuildContext context, String id, String name, String description, String imagePath, double price, int quantity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          productId: id,
          productName: name,
          productDescription: description,
          productImagePath: imagePath,
          productPrice: price,
          productQuantity: quantity,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _deleteProduct(String id) async {
    final products = FirebaseFirestore.instance.collection('products');
    await products.doc(id).delete();
    setState(() {});
  }

  void _showItemActions(BuildContext context, String id, String name, String description, String imagePath, double price, int quantity) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editProduct(context, id, name, description, imagePath, price, quantity);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsightScreen(), // Replace with your actual insights screen
      ),
    );
  }
}
