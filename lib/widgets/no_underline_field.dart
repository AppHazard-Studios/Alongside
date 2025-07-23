// lib/widgets/no_underline_field.dart - UPDATED FOR iOS STANDARD SIZING
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label - iOS Callout size (16pt)
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.2), // iOS callout size
            color: AppColors.textSecondary,
            fontFamily: '.SF Pro Text',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)),

        // Input field container to ensure proper height
        Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveUtils.scaledFormHeight(context, baseHeight: 32),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.2), // iOS body size
              color: AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
              fontWeight: FontWeight.w400,
            ),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.scaledSpacing(context, 8),
              horizontal: 0,
            ),
            decoration: null,
            suffix: suffixIcon,
            placeholderStyle: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.2),
              color: const Color(0xFFBEBEC0), // iOS placeholder color
              fontFamily: '.SF Pro Text',
              fontWeight: FontWeight.w400,
            ),
            autofocus: false,
            cursorColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}