import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        userName: "John Doe", // Replace with actual user name
        logoStyle: LogoStyle.style1,
      ),
      body: // Your profile content
    );
  }
} 