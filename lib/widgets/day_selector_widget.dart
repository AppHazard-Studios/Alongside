// lib/widgets/day_selector_widget.dart - FIXED CONSISTENT TEXT SCALING
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/day_selection_data.dart';
import '../utils/text_styles.dart'; // FIXED: Ensure text_styles import
import '../utils/colors.dart';

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
        height: 280,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    'Cancel',
                    // FIXED: Use proper scaled button instead of raw TextStyle
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text(
                    'Done',
                    // FIXED: Use proper scaled button instead of raw TextStyle
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  color: CupertinoColors.systemBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Schedule',
                      // FIXED: Use proper scaled callout instead of raw TextStyle
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: CupertinoColors.label,
                      ),
                    ),
                    Text(
                      'Choose when to be reminded to check in',
                      // FIXED: Use proper scaled subhead instead of raw TextStyle
                      style: AppTextStyles.scaledSubhead(context).copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Select Days',
            // FIXED: Use proper scaled subhead instead of raw TextStyle
            style: AppTextStyles.scaledSubhead(context).copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 12),
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
            const SizedBox(height: 24),

            Text(
              'Reminder Time',
              // FIXED: Use proper scaled subhead instead of raw TextStyle
              style: AppTextStyles.scaledSubhead(context).copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showTimePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formattedReminderTime,
                      // FIXED: Use proper scaled callout instead of raw TextStyle
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: CupertinoColors.label,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Repeat',
              // FIXED: Use proper scaled subhead instead of raw TextStyle
              style: AppTextStyles.scaledSubhead(context).copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 12),
            _buildIntervalSelector(),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.bell_fill,
                    color: CupertinoColors.systemBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPreviewText(),
                          // FIXED: Use proper scaled subhead instead of raw TextStyle
                          style: AppTextStyles.scaledSubhead(context).copyWith(
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'At $_formattedReminderTime',
                          // FIXED: Use proper scaled caption instead of raw TextStyle
                          style: AppTextStyles.scaledCaption(context).copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.bell_slash,
                    color: CupertinoColors.secondaryLabel,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No reminders will be sent',
                    // FIXED: Use proper scaled subhead instead of raw TextStyle
                    style: AppTextStyles.scaledSubhead(context).copyWith(
                      color: CupertinoColors.secondaryLabel,
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

  Widget _buildDayCircle(String letter, int dayNumber) {
    final isSelected = _selectedDays.contains(dayNumber);

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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey6,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey4,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            letter,
            // FIXED: Use proper scaled callout instead of raw TextStyle
            style: AppTextStyles.scaledCallout(context).copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? CupertinoColors.white : CupertinoColors.label,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Column(
      children: [
        _buildIntervalOption('Weekly', RepeatInterval.weekly),
        const SizedBox(height: 8),
        _buildIntervalOption('Every 2 weeks', RepeatInterval.biweekly),
        const SizedBox(height: 8),
        _buildIntervalOption('Monthly', RepeatInterval.monthly),
        const SizedBox(height: 8),
        _buildIntervalOption('Every 3 months', RepeatInterval.quarterly),
        const SizedBox(height: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CupertinoColors.systemBlue.withOpacity(0.1) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey3,
                  width: 2,
                ),
                color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.white,
              ),
              child: isSelected
                  ? const Icon(
                CupertinoIcons.checkmark,
                size: 12,
                color: CupertinoColors.white,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              // FIXED: Use proper scaled callout instead of raw TextStyle
              style: AppTextStyles.scaledCallout(context).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.label,
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