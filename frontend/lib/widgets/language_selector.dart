import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'translated_text.dart';  // Add this import

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  String _getLanguageDisplay(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Color(0xFF4A90E2).withOpacity(0.2),
            width: 1,
          ),
        ),
        offset: Offset(0, 40),
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                _getLanguageDisplay(languageProvider.currentLanguage),
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF2C3E50),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          'en',
          'hi',
          'ta',
          'te',
          // Add other supported languages here
        ].map((String language) {
          return PopupMenuItem<String>(
            value: language,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLanguageDisplay(language),
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: language == languageProvider.currentLanguage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (language == languageProvider.currentLanguage)
                    Icon(
                      Icons.check,
                      color: Color(0xFF4A90E2),
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        onSelected: (String language) {
          languageProvider.setLanguage(language);
        },
      ),
    );
  }
}