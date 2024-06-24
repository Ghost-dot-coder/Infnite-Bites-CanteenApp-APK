import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../user/info.dart';
import 'admin history.dart';

class AdminSettings extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<AdminSettings> {
  final _auth = FirebaseAuth.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _currentPasswordErrorText = '';
  String _newPasswordErrorText = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: Text('Change Password'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _historyButtonAction(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('History'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _navigateToAppInfoScreen(context),
              child: Text('Additional Settings'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAppInfoScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppInfoScreen(),
      ),
    );
  }

  void _historyButtonAction(BuildContext context) {
    // Implement the action for the new button here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminHistoryScreen(),
      ),
    );
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Current Password',
                errorText: _currentPasswordErrorText.isNotEmpty ? _currentPasswordErrorText : null,
              ),
              onChanged: (_) {
                setState(() {
                  _currentPasswordErrorText = '';
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                errorText: _newPasswordErrorText.isNotEmpty ? _newPasswordErrorText : null,
              ),
              onChanged: (_) {
                setState(() {
                  _newPasswordErrorText = '';
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearErrorMessages();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updatePassword(
              context,
              _currentPasswordController.text,
              _newPasswordController.text,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _updatePassword(
      BuildContext context,
      String currentPassword,
      String newPassword,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
        ),
      );
    } catch (e) {
      print('Failed to update password: $e');
      setState(() {
        if (e.toString().contains('wrong-password')) {
          _currentPasswordErrorText = 'Incorrect current password. Please try again.';
        } else if (e.toString().contains('weak-password')) {
          _newPasswordErrorText = 'New password is too weak. Please choose a stronger password.';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update password: $e'),
            ),
          );
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearErrorMessages() {
    setState(() {
      _currentPasswordErrorText = '';
      _newPasswordErrorText = '';
    });
  }

  void _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
            (Route<dynamic> route) => false,
      ); // Clear the navigation stack
    } catch (e) {
      print('Failed to sign out try again');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign out try again'),
        ),
      );
    }
  }
}
