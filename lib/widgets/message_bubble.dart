import 'package:flutter/material.dart';
import '../utils/text_styles.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  final bool isSelectable;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.onTap,
    this.isSelectable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Limit width to 85% of screen but allow narrower for shorter messages
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: IntrinsicWidth(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelectable
                        ? Colors.white
                        : const Color(0xFF007AFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelectable
                        ? Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text(
                    message,
                    style: isSelectable
                        ? AppTextStyles.bodyText
                        : AppTextStyles.accentText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
