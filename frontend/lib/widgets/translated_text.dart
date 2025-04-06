import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_loader_service.dart';

class TranslatedText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Map<String, String>? params;

  const TranslatedText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    String? translatedText = languageProvider.getTranslation(translationKey);
    
    print('TranslatedText: key=$translationKey, translation=$translatedText');
    
    if (translatedText == null) {
      print('Warning: No translation found for key: $translationKey');
      translatedText = translationKey;
    }
    
    // Replace placeholders with actual values if params are provided
    if (params != null) {
      params!.forEach((key, value) {
        translatedText = translatedText!.replaceAll('{$key}', value);
      });
    }
    
    return Text(
      translatedText!,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}