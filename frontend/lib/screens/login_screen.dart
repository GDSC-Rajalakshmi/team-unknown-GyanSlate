import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        logoStyle: LogoStyle.style1,
      ),
      body: // Your login content
    );
  }
} 