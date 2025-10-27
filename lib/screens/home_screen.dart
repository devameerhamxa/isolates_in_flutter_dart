// ignore_for_file: void_checks

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/button_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Flutter Isolates')),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ButtonProvider>().resetCount();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<ButtonProvider>(
              builder: (context, provider, child) {
                return Text(
                  'Total Count: ${provider.buttonClickCount}',
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
            Image.asset('assets/gif/dancing-banana.gif'),
            const SizedBox(height: 30),

            // Button 1: Simple Increment
            ElevatedButton(
              onPressed: () {
                context.read<ButtonProvider>().testComputation();
              },
              child: const Text('Button 1 (+1)'),
            ),
            const SizedBox(height: 20),

            // Button 2: Heavy Computation in Isolate
            ElevatedButton(
              onPressed: () async {
                // Perform heavy computation in isolate
                await context.read<ButtonProvider>().incrementButton2();
              },
              child: const Text('Button 2 (Heavy Computation)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<ButtonProvider>().incrementButton3();
              },
              child: const Text('Button 3 (+3)'),
            ),
          ],
        ),
      ),
    );
  }
}
