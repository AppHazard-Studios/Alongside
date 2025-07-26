// lib/widgets/day_selector_widget.dart - FIXED TEXT CENTERING AND OVERFLOW ISSUES
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/day_selection_data.dart';
import '../utils/text_styles.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

class DaySelectorWidget extends StatefulWidget {
  final DaySelectionData? initialData;
  final Function(DaySelectionData?) onChanged;
  final String reminderTime;
  final Function(String) onTimeChanged;

  const DaySelectorWidget({
    Key? key,
    this.initialData,
    required this.onChanged,
    required this.reminderTime,
    required this.onTimeChanged,
  }) : super(key: key);

  @override
  State<DaySelectorWidget> createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget> {
  late Set<int> _selectedDays;
  late RepeatInterval _interval;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedDays = Set<int>.from(widget.initialData!.selectedDays);
      _interval = widget.initialData!.interval;
    } else {
      _selectedDays = {};
      _interval = RepeatInterval.weekly;
    }
  }

  String get _reminderTimeStr => widget.reminderTime;

  String get _formattedReminderTime {
    final parts = _reminderTimeStr.split(':');
    if (parts.length == 2) {
      int hour = int.tryParse(parts[0]) ?? 9;
      int minute = int.tryParse(parts[1]) ?? 0;

      final period = hour < 12 ? 'AM' : 'PM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    }
    return "9:00 AM";
  }

  void _updateData() {
    if (_selectedDays.isNotEmpty) {
      widget.onChanged(DaySelectionData(
        selectedDays: _selectedDays,
        interval: _interval,
      ));
    } else {
      widget.onChanged(null);
    }
  }

  void _showTimePicker() {
    final parts = _reminderTimeStr.split(':');
    int currentHour = int.tryParse(parts[0]) ?? 9;
    int currentMinute = int.tryParse(parts[1]) ?? 0;

    final initialDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      currentHour,
      currentMinute,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: ResponsiveUtils.scaledContainerSize(context, 250),
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: ResponsiveUtils.scaledContainerSize(context, 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.scaledButton(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: AppTextStyles.scaledButton(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dateTime) {
                  final newTimeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                  widget.onTimeChanged(newTimeStr);
                },
                use24hFormat: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveUtils.scaledContainerSize(context, 32),
                height: ResponsiveUtils.scaledContainerSize(context, 32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.bell_fill,
                  color: AppColors.primary,
                  // 🔧 FIXED: Proper icon scaling
                  size: ResponsiveUtils.scaledIconSize(context, 16),
                ),
              ),
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Schedule',
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Choose when to be reminded to check in',
                      style: AppTextStyles.scaledSubhead(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

          Text(
            'Select Days',
            style: AppTextStyles.scaledSubhead(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),

          // 🔧 FIXED: Day selector with proper centering
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayCircle('M', 1),
              _buildDayCircle('T', 2),
              _buildDayCircle('W', 3),
              _buildDayCircle('T', 4),
              _buildDayCircle('F', 5),
              _buildDayCircle('S', 6),
              _buildDayCircle('S', 7),
            ],
          ),

          if (_selectedDays.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

            Text(
              'Reminder Time',
              style: AppTextStyles.scaledSubhead(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
            GestureDetector(
              onTap: _showTimePicker,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaledSpacing(context, 14),
                  vertical: ResponsiveUtils.scaledSpacing(context, 10),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formattedReminderTime,
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: ResponsiveUtils.scaledIconSize(context, 12),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

            Text(
              'Repeat',
              style: AppTextStyles.scaledSubhead(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
            _buildIntervalSelector(),

            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

            Container(
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.bell_fill,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 14),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPreviewText(),
                          style: AppTextStyles.scaledSubhead(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'At $_formattedReminderTime',
                          style: AppTextStyles.scaledCaption(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),

            // 🔧 FIXED: No overflow and proper text wrapping
            Container(
              width: double.infinity, // Ensure full width
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.bell_slash,
                    color: AppColors.textSecondary,
                    size: ResponsiveUtils.scaledIconSize(context, 14),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
                  Expanded( // 🔧 FIXED: Expanded to prevent overflow
                    child: Text(
                      'No reminders will be sent',
                      style: AppTextStyles.scaledSubhead(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2, // Allow wrapping if needed
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🔧 FIXED: Day circle with perfect text centering
  Widget _buildDayCircle(String letter, int dayNumber) {
    final isSelected = _selectedDays.contains(dayNumber);
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 36);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayNumber);
          } else {
            _selectedDays.add(dayNumber);
          }
          _updateData();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        // 🔧 FIXED: Perfect center alignment
        child: Center(
          child: Text(
            letter,
            style: AppTextStyles.scaledCallout(context).copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
              height: 1.0, // Ensure no extra line height
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Column(
      children: [
        _buildIntervalOption('Weekly', RepeatInterval.weekly),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
        _buildIntervalOption('Every 2 weeks', RepeatInterval.biweekly),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
        _buildIntervalOption('Monthly', RepeatInterval.monthly),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
        _buildIntervalOption('Every 3 months', RepeatInterval.quarterly),
        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
        _buildIntervalOption('Every 6 months', RepeatInterval.semiannually),
      ],
    );
  }

  Widget _buildIntervalOption(String title, RepeatInterval interval) {
    final isSelected = _interval == interval;

    return GestureDetector(
      onTap: () {
        setState(() {
          _interval = interval;
          _updateData();
        });
      },
      child: Container(
        width: double.infinity, // 🔧 FIXED: Full width to prevent overflow
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 14),
          vertical: ResponsiveUtils.scaledSpacing(context, 10),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.scaledContainerSize(context, 18),
              height: ResponsiveUtils.scaledContainerSize(context, 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.white,
              ),
              child: isSelected
                  ? Icon(
                CupertinoIcons.checkmark,
                size: ResponsiveUtils.scaledIconSize(context, 10),
                color: Colors.white,
              )
                  : null,
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
            Expanded( // 🔧 FIXED: Expanded to prevent overflow
              child: Text(
                title,
                style: AppTextStyles.scaledCallout(context).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText() {
    final data = DaySelectionData(
      selectedDays: _selectedDays,
      interval: _interval,
    );

    return data.getDescription();
  }
}