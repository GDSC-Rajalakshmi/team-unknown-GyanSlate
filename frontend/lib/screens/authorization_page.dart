import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/translated_text.dart';
import '../widgets/language_selector.dart';
import 'dart:math';
import '../services/translation_loader_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthorizationPage extends StatefulWidget {
  const AuthorizationPage({super.key});

  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _authKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;
  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _authKeyController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/authorise'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authKeyController.text}',
          },
        );

        if (response.statusCode == 200) {
          // Parse the response and get the token
          final token = _authKeyController.text;
          
          // Store the token securely
          await _storage.write(key: 'token', value: token);
          
          // Verify the token was stored by reading it back
          final storedToken = await _storage.read(key: 'token');
          
          // Navigate to home page
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: TranslatedText(
                  'invalidAuthKey',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText(
                'networkError',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? screenSize.width * 0.1 : 24,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageHeader(),
                  SizedBox(height: 32),
                  _buildAuthForm(isWeb, isLandscape, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      children: [
        Container(
          height: 130,
          width: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // No background color
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4A90E2).withOpacity(0.6), // soft glow
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Transform.scale(
              scale: 1.9, // Increase this to make the image larger
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        TranslatedText(
          'Authorization',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(bool isWeb, bool isLandscape, ThemeData theme) {
    return Container(
      width: isWeb ? 600 : double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('enterAuthKey', theme),
            SizedBox(height: 24),
            _buildAuthKeyField(theme),
            SizedBox(height: 32),
            _buildSubmitButton(isLandscape, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String translationKey, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4A90E2).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: TranslatedText(
            translationKey,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthKeyField(ThemeData theme) {
    final translationService = TranslationLoaderService();
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _authKeyController,
            obscureText: _isObscured,
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 15,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: translationService.getTranslation('enterAuthKeyHint', languageProvider.currentLanguage),
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: Color(0xFFF8FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
              prefixIcon: Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFF4A90E2),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                  size: 22,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return translationService.getTranslation('pleaseEnterAuthKey', languageProvider.currentLanguage);
              }
              return null;
            },
          ),
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF4A90E2),
                  size: 16,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TranslatedText(
                    'authKeyInfo',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLandscape, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: isLandscape ? 52 : 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.25),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TranslatedText(
                    'authenticate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
} 