import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'custom_header.dart';

class BaseScreen extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const BaseScreen({
    super.key,
    required this.body,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserProvider>().userName;
    
    return Scaffold(
      appBar: CustomHeader(
        appName: "Your App Name",
        userName: userName,
        logoStyle: LogoStyle.style1,
      ),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
} 