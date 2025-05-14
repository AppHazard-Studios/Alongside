// lib/widgets/no_underline_field.dart - Fixed to prevent placeholder overlapping
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/text_styles.dart';

class NoUnderlineField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;

  const NoUnderlineField({
    Key? key,
    required this.controller,
    required this.label,
    this.placeholder = '',
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  State<NoUnderlineField> createState() => _NoUnderlineFieldState();
}

class _NoUnderlineFieldState extends State<NoUnderlineField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    // Set initial state based on if controller already has text
    _hasText = widget.controller.text.isNotEmpty;

    // Listen for changes to the text field
    widget.controller.addListener(_updateHasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasText);
    super.dispose();
  }

  void _updateHasText() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: AppTextStyles.formLabel,
        ),

        const SizedBox(height: 8),

        // Input field with NO decoration at all - this guarantees no yellow underlines
        Stack(
          children: [
            // The actual text field
            TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              style: AppTextStyles.inputText,
              // This is the key - completely empty decoration with no underlines
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 8),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                // No other decoration properties
              ),
            ),

            // Placeholder text (only shown when empty)
            if (!_hasText)
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: Text(
                    widget.placeholder,
                    style: AppTextStyles.placeholder,
                  ),
                ),
              ),

            // Suffix icon if provided
            if (widget.suffixIcon != null)
              Positioned(
                right: 0,
                top: 0,
                child: widget.suffixIcon!,
              ),
          ],
        ),
      ],
    );
  }
}