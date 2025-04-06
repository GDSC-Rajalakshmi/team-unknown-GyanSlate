import 'package:flutter/material.dart';
import '../services/translation_loader_service.dart';
import 'translated_text.dart';

class TranslatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintKey;
  final Function(String)? onSubmitted;
  final bool showWave;
  final String? errorKey;
  final String? labelKey;

  const TranslatedTextField({
    super.key,
    required this.controller,
    required this.hintKey,
    this.onSubmitted,
    this.showWave = false,
    this.errorKey,
    this.labelKey,
  });

  @override
  State<TranslatedTextField> createState() => _TranslatedTextFieldState();
}

class _TranslatedTextFieldState extends State<TranslatedTextField> {
  final _translationService = TranslationLoaderService();
  bool _hasError = false;
  bool _isFocused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final hasError = widget.controller.text.isEmpty;
    if (hasError != _hasError) {
      setState(() => _hasError = hasError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TranslatedText(
              widget.labelKey!,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        Stack(
          children: [
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError ? Colors.red : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              onSubmitted: widget.onSubmitted,
            ),
            if (widget.controller.text.isEmpty && !_isFocused)
              Positioned.fill(
                child: Center(
                  child: IgnorePointer(
                    child: TranslatedText(
                      widget.hintKey,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_hasError && widget.errorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 16.0),
            child: TranslatedText(
              widget.errorKey!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
} 