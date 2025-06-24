// lib/widgets/no_underline_field.dart
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/responsive_utils.dart';

class NoUnderlineField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.formLabel.copyWith(
            fontSize: ResponsiveUtils.scaledFontSize(context, 14),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),

        // Using CupertinoTextField instead of Material TextField
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          style: AppTextStyles.inputText.copyWith(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
          ),
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.scaledSpacing(context, 10),
            horizontal: 0,
          ),
          decoration: null,
          suffix: suffixIcon,
          placeholderStyle: AppTextStyles.placeholder.copyWith(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
          ),
          autofocus: false,
          cursorColor: AppColors.primary,
        ),
      ],
    );
  }
}