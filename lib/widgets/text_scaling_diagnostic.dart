// lib/widgets/text_scaling_diagnostic.dart
// Add this widget to your app to debug text scaling issues

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../utils/colors.dart';

class TextScalingDiagnostic extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const TextScalingDiagnostic({
    Key? key,
    required this.child,
    this.showOverlay = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: _DiagnosticOverlay(),
        ),
      ],
    );
  }
}

class _DiagnosticOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rawScale = MediaQuery.of(context).textScaleFactor;
    final hasAccessibility = ResponsiveUtils.hasAccessibilityScaling(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasAccessibility
            ? Colors.orange.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Text Scale: ${(rawScale * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: '.SF Pro Text',
            ),
          ),
          if (hasAccessibility) ...[
            const SizedBox(height: 4),
            const Text(
              '⚠️ Accessibility ON',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const Text(
              'Text sizes fixed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Add this screen to test all text styles
class TextStyleTestScreen extends StatelessWidget {
  const TextStyleTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Text Style Test',
          style: AppTextStyles.scaledNavTitle(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStyleExample(
              context,
              'Large Title (34pt)',
              AppTextStyles.scaledLargeTitle(context),
              'Welcome to Alongside',
            ),
            _buildStyleExample(
              context,
              'Title 1 (28pt)',
              AppTextStyles.scaledTitle1(context),
              'Alongside',
            ),
            _buildStyleExample(
              context,
              'Title 2 (22pt)',
              AppTextStyles.scaledTitle2(context),
              'Your Friends',
            ),
            _buildStyleExample(
              context,
              'Title 3 (20pt)',
              AppTextStyles.scaledTitle3(context),
              'Recent Messages',
            ),
            _buildStyleExample(
              context,
              'Headline (17pt semibold)',
              AppTextStyles.scaledHeadline(context),
              'John Smith',
            ),
            _buildStyleExample(
              context,
              'Body (17pt)',
              AppTextStyles.scaledBody(context),
              'This is the main body text used throughout the app.',
            ),
            _buildStyleExample(
              context,
              'Callout (16pt)',
              AppTextStyles.scaledCallout(context),
              'Secondary content and form fields use this size.',
            ),
            _buildStyleExample(
              context,
              'Subhead (15pt)',
              AppTextStyles.scaledSubhead(context),
              'Smaller labels and descriptions',
            ),
            _buildStyleExample(
              context,
              'Footnote (13pt)',
              AppTextStyles.scaledFootnote(context),
              'Last seen 2 hours ago',
            ),
            _buildStyleExample(
              context,
              'Caption (12pt)',
              AppTextStyles.scaledCaption(context),
              'Very small text for labels',
            ),
            _buildStyleExample(
              context,
              'Button (17pt semibold)',
              AppTextStyles.scaledButton(context).copyWith(color: AppColors.primary),
              'Save Changes',
            ),
            _buildStyleExample(
              context,
              'Section Header (13pt)',
              AppTextStyles.scaledSectionHeader(context),
              'NOTIFICATION SETTINGS',
            ),

            const SizedBox(height: 32),

            // System info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Info',
                    style: AppTextStyles.scaledHeadline(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Text Scale Factor: ${MediaQuery.of(context).textScaleFactor.toStringAsFixed(2)}',
                    style: AppTextStyles.scaledBody(context),
                  ),
                  Text(
                    'Screen Width: ${MediaQuery.of(context).size.width.toStringAsFixed(0)}',
                    style: AppTextStyles.scaledBody(context),
                  ),
                  Text(
                    'Accessibility Scaling: ${ResponsiveUtils.hasAccessibilityScaling(context) ? "ON" : "OFF"}',
                    style: AppTextStyles.scaledBody(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleExample(
      BuildContext context,
      String label,
      TextStyle style,
      String example,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.scaledCaption(context),
          ),
          const SizedBox(height: 4),
          Text(
            example,
            style: style,
          ),
        ],
      ),
    );
  }
}