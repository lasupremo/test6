import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rekindle/pages/auth/register_page.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {

  Widget get _signUpPage => const RegisterPage(); 


  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This action is irreversible. All content associated with your account will be permanently deleted. Do you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Error: Not logged in")),
      );
      return;
    }

    try {
      final res = await supabase.functions.invoke(
        'delete-account',
        body: {'userId': user.id},
      );

      if (!mounted) return; 

      if (res.status != 200) {
        messenger.showSnackBar(SnackBar(content: Text("Error: ${res.data}")));
      } else {
        await supabase.auth.signOut();
        
        if (!mounted) return; 
        
        messenger.showSnackBar(
          const SnackBar(content: Text("Account deleted successfully")),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => _signUpPage),
          (Route<dynamic> route) => false, 
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Manage Account"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(CupertinoIcons.trash),
              label: const Text("Delete Account"),
              onPressed: _confirmDeleteAccount, 
            ),
          ],
        ),
      ),
    );
  }
}