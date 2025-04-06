import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        userName: "John Doe", // Replace with actual user name
        logoStyle: LogoStyle.style1,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            // Your drawer items
          ],
        ),
      ),
      body: // Your home content
    );
  }
} 