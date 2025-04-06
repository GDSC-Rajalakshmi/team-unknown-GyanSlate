import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        userName: "John Doe",
        primaryColor: Colors.indigo, // Choose your color
        logoStyle: LogoStyle.style2, // Choose from style1 to style4
      ),
      body: Column(
        children: [
          // Your page content here
        ],
      ),
    );
  }
} 