import 'package:flutter/material.dart';
import '../components/drawer_tile.dart';
import '../pages/settings_page.dart';
import 'package:go_router/go_router.dart';


class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // header
          const DrawerHeader(child: Icon(Icons.edit)),

          const SizedBox(height: 25),

          // home tile
          DrawerTile(
            title: "Home",
            leading: const Icon(Icons.home),
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),

          // settings tile
          DrawerTile(
            title: "Settings",
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
