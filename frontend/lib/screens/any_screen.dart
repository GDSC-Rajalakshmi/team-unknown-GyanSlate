import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';

class AnyScreen extends StatelessWidget {
  const AnyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      userName: "John Doe", // Optional
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your screen content
          ],
        ),
      ),
      drawer: Drawer( // Optional
        // Your drawer content
      ),
      floatingActionButton: FloatingActionButton( // Optional
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
} 