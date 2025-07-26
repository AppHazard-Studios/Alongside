// lib/widgets/no_underline_field.dart - FIXED TEXT ALIGNMENT AND CENTERING
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
        // Label - Using proper iOS Callout style
        Text(
          label,
          style: AppTextStyles.scaledFormLabel(context),
        ),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)),

        // 🔧 FIXED: Proper text field alignment and centering
        Container(
          // Ensure minimum height for touch targets
          constraints: BoxConstraints(
            minHeight: ResponsiveUtils.scaledFormHeight(context, baseHeight: 36),
          ),
          // Center the text field content vertically
          alignment: Alignment.centerLeft,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            style: AppTextStyles.scaledFormInput(context),
            // 🔧 FIXED: Proper vertical centering with responsive padding
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.scaledSpacing(context, 6), // Reduced for better centering
              horizontal: 0,
            ),
            decoration: null,
            suffix: suffixIcon,
            placeholderStyle: AppTextStyles.scaledTextStyle(
              context,
              AppTextStyles.placeholder,
            ),
            autofocus: false,
            cursorColor: AppColors.primary,
            // 🔧 FIXED: Ensure proper text alignment
            textAlign: TextAlign.left,
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
      ],
    );
  }
}