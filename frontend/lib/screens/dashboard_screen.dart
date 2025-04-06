import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        userName: "John Doe",
        logoStyle: LogoStyle.style1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your existing dashboard content
          ],
        ),
      ),
    );
  }
} 