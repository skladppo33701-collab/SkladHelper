import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoaderDashboard extends StatelessWidget {
  const LoaderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Панель Грузчика"), // Loader Dashboard
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.orangeAccent),
            SizedBox(height: 16),
            Text("Интерфейс грузчика в разработке"),
          ],
        ),
      ),
    );
  }
}
