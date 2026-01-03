import 'package:flutter/material.dart';

class DriversPage extends StatelessWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: const Center(child: Text('Drivers page (coming soon)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add Driver (TODO)')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
