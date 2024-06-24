import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home.dart';
import 'order.dart';
import 'cart.dart';
import 'settings.dart';

void main() {
  runApp(HomeScreen(username: TextEditingController(), openCart: true));
}

class HomeScreen extends StatelessWidget {
  final TextEditingController username;
  final bool openCart;

  HomeScreen({required this.username, this.openCart = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
        ),
      ),
      home: MyHomePage(selectedIndex: openCart ? 1 : 0),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int selectedIndex;

  MyHomePage({required this.selectedIndex});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  DateTime? lastPressed;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;

  final List<Color> _backgroundColor = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
        if (!_isConnected) {
          _currentIndex = 2; // Orders screen index
          _showNetworkErrorSnackbar();
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      if (!_isConnected) {
        _currentIndex = 2; // Orders screen index
        _showNetworkErrorSnackbar();
      }
    });
  }

  final List<Widget> _children = [
    HomeTab(),
    CartScreen(),
    OrdersScreen(),
    SettingsScreen(),
  ];

  void onTabTapped(int index) {
    if (_isConnected || index == 2) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      _showNetworkErrorSnackbar();
    }
  }

  Future<bool> _handleWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      final now = DateTime.now();
      if (lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2)) {
        lastPressed = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Press back again to exit')),
        );
        return false;
      } else {
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Are you sure you want to exit?"),
            content: const Text("This action will exit the application."),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        return shouldPop ?? false;
      }
    }
  }

  void _showNetworkErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No network connection. Cannot navigate to other screens.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor[_currentIndex];

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: Container(
          height: 60,
          color: backgroundColor,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.blueGrey,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }
}
