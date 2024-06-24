import 'package:flutter/material.dart';
import 'admin_home.dart';
import 'adminsettings.dart';
import 'orderlist.dart';
import 'qr_reader.dart';

class AdminScreen extends StatelessWidget {
  final TextEditingController username;
  AdminScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'tkin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyAdminPage(),
    );
  }
}

class MyAdminPage extends StatefulWidget {
  @override
  _MyAdminPageState createState() => _MyAdminPageState();
}

class _MyAdminPageState extends State<MyAdminPage> {
  int _currentIndex = 0;
  DateTime? lastPressed;

  final List<Widget> _children = [
    AdminHomeTab(),
    QRReader(),
    OrderListScreen(),
    AdminSettings(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
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
            title: Text("Are you sure you want to exit?"),
            content: Text("This action will exit the application."),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          items: const [
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Icon(Icons.qr_code_scanner),
              label: 'QR Reader',
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Icon(Icons.list),
              label: 'Order List',
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
