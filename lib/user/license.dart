import 'package:flutter/material.dart';

class LicenseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copyright Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
                '© 2024 All rights reserved.\n\n'
                'This app and its contents are protected by copyright law. '
                'Unauthorized reproduction or distribution of this app, '
                'or any portion of it, may result in severe civil and criminal penalties, '
                'and will be prosecuted to the maximum extent possible under the law.',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
