import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productDescription;
  final String productImagePath;
  final double productPrice;
  final int productQuantity;

  EditProductScreen({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImagePath,
    required this.productPrice,
    required this.productQuantity,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productName);
    _descriptionController = TextEditingController(text: widget.productDescription);
    _priceController = TextEditingController(text: widget.productPrice.toString());
    _quantityController = TextEditingController(text: widget.productQuantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }


  Future<String> _uploadImage(File image) async {
    String fileName = 'products/${widget.productId}/${DateTime.now().millisecondsSinceEpoch}.png';
    UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _updateProduct() async {
    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImage(_image!);
    }

    final products = FirebaseFirestore.instance.collection('products');
    await products.doc(widget.productId).update({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.parse(_quantityController.text),
      'imagePath': imageUrl ?? widget.productImagePath,
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: _image != null
                  ? Image.file(_image!)
                  : widget.productImagePath.isNotEmpty
                  ? Image.network(widget.productImagePath)
                  : Container(
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 50),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProduct,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
