import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';  // Make sure this import path is correct

class YourScreen extends StatelessWidget {
  const YourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(  // Add the CustomHeader here as the appBar
        appName: "Your App Name",
        userName: "User Name",
        logoStyle: LogoStyle.style1,
      ),
      body: // Your existing body content
    );
  }
} 