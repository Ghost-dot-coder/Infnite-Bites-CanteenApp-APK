import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class AppVersionScreen extends StatefulWidget {
  @override
  _AppVersionScreenState createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  final ShorebirdCodePush shorebirdCodePush = ShorebirdCodePush();
  String _currentPatchNumber = 'Unknown';

  @override
  void initState() {
    super.initState();
    _getCurrentPatchNumber();
  }

  void _getCurrentPatchNumber() async {
    final patchNumber = await shorebirdCodePush.currentPatchNumber();
    setState(() {
      _currentPatchNumber = patchNumber?.toString() ?? 'None';
    });
  }

  Future<void> _checkForUpdates() async {
    final isUpdateAvailable = await shorebirdCodePush.isNewPatchAvailableForDownload();

    if (isUpdateAvailable) {
      await shorebirdCodePush.downloadUpdateIfAvailable();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update downloaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No updates available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Version'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              // title: Text('Current Patch Number'),
              // subtitle: Text(_currentPatchNumber),
              title: Text('About this version'),titleTextStyle: TextStyle(fontWeight: FontWeight.bold,color: Colors.black),
              subtitle: Text('-Improved welcome screen\n-Fixed other known issues'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _checkForUpdates,
              child: Text('Check for update'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
