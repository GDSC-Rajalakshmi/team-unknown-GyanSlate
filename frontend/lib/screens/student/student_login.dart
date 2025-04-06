import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/translated_text.dart';
import '../../services/translation_loader_service.dart';
import 'package:flutter/material.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  State<StudentLogin> createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  String? _selectedClass;
  String? _selectedState;
  bool _isLoading = false;

  // Predefined lists for dropdowns
  final List<String> _states = ['Tamil Nadu', 'Andhra Pradesh', 'Delhi'];
  final List<String> _classes = List<String>.generate(7, (i) => (i + 4).toString());  // Generates ['4', '5', '6', '7', '8', '9', '10']

  // Method to clear stored credentials
  Future<void> _clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This will clear all stored preferences
  }

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
    _ensureTranslationsLoaded();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSignedUp = prefs.getBool('hasSignedUp') ?? false;
    
    if (hasSignedUp && mounted) {
      Navigator.pushReplacementNamed(context, '/student'); // Changed from '/student-dashboard'
    }
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate() && _selectedState != null && _selectedClass != null) {
      setState(() => _isLoading = true);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Debug print before saving
        print('About to save student name: ${_nameController.text}');
        
        // Store user details with consistent keys
        await Future.wait([
          prefs.setString('student_name', _nameController.text.trim()),  // Added trim()
          prefs.setString('rollNumber', _rollNumberController.text),
          prefs.setString('class', _selectedClass!),
          prefs.setString('state', _selectedState!),
          prefs.setString('user_state', _selectedState!),
          prefs.setInt('user_points', 100),
          prefs.setBool('hasSignedUp', true),
        ]);

        // Verify the save was successful
        final savedName = await prefs.getString('student_name');
        print('Verified saved student name: $savedName');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/student');
        }
      } catch (e) {
        print('Error during signup: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _ensureTranslationsLoaded() async {
    final translationService = TranslationLoaderService();
    await translationService.loadTranslations();
    if (mounted) {
      setState(() {}); // Trigger rebuild after translations are loaded
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    // Remove the lines trying to dispose _classController and _stateController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationLoaderService();
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'EdGenius',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    translationService.getTranslation('student.login.welcomeBack', languageProvider.currentLanguage),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translationService.getTranslation('student.login.signInContinue', languageProvider.currentLanguage),
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2C3E50).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'fullName',
                            hint: 'enterName',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _rollNumberController,
                            label: 'rollNumber',
                            hint: 'enterRollNumber',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            value: _selectedClass,
                            items: _classes,
                            label: 'class',
                            hint: 'selectClass',
                            icon: Icons.school,
                            onChanged: (String? newValue) {
                              setState(() => _selectedClass = newValue);
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            value: _selectedState,
                            items: _states,
                            label: 'state',
                            hint: 'selectState',
                            icon: Icons.location_on,
                            onChanged: (String? newValue) {
                              setState(() => _selectedState = newValue);
                            },
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    translationService.getTranslation(
                                      'student.login.signUp',
                                      languageProvider.currentLanguage
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final translationService = TranslationLoaderService();
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: translationService.getTranslation('student.login.$label', languageProvider.currentLanguage),
        hintText: translationService.getTranslation('student.login.$hint', languageProvider.currentLanguage),
        prefixIcon: Icon(icon, color: Color(0xFF4A90E2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(color: Color(0xFF2C3E50)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return translationService.getTranslation('student.login.error.general', languageProvider.currentLanguage);
        }
        return null;
      },
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final translationService = TranslationLoaderService();
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: translationService.getTranslation('student.login.$label', languageProvider.currentLanguage),
        prefixIcon: Icon(icon, color: Color(0xFF4A90E2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            label == 'state' 
              ? translationService.getTranslation('student.login.${label}s.$item', languageProvider.currentLanguage)
              : item,
            style: TextStyle(color: Color(0xFF2C3E50)),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null 
        ? translationService.getTranslation('student.login.$hint', languageProvider.currentLanguage)
        : null,
      dropdownColor: Colors.white,
      style: TextStyle(color: Color(0xFF2C3E50)),
    );
  }
}
