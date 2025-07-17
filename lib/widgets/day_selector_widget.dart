// lib/widgets/day_selector_widget.dart - UPDATED WITH INTEGRATED TIME PICKER
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/day_selection_data.dart';

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
  late String _reminderTimeStr;

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
    _reminderTimeStr = widget.reminderTime;
  }

  // Parse time for display in 12-hour format
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
    // Extract current hours and minutes from string
    final parts = _reminderTimeStr.split(':');
    int currentHour = int.tryParse(parts[0]) ?? 9;
    int currentMinute = int.tryParse(parts[1]) ?? 0;

    // Create initial DateTime for the picker
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
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
                  setState(() {
                    // Update time string in HH:MM format
                    _reminderTimeStr =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                    widget.onTimeChanged(_reminderTimeStr);
                  });
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
          // Header
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Schedule',
                      style: TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 16,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                    Text(
                      'Choose when to be reminded to check in',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Day selector
          const Text(
            'Select Days',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
              fontFamily: '.SF Pro Text',
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

            // Time picker (now integrated)
            const Text(
              'Reminder Time',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 14,
                fontFamily: '.SF Pro Text',
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
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

            // Repeat interval selector
            const Text(
              'Repeat',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 14,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 12),
            _buildIntervalSelector(),

            const SizedBox(height: 20),

            // Preview
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                        Text(
                          'At $_formattedReminderTime',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                            fontFamily: '.SF Pro Text',
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
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.bell_slash,
                    color: CupertinoColors.secondaryLabel,
                    size: 16,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'No reminders will be sent',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                      fontFamily: '.SF Pro Text',
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? CupertinoColors.white : CupertinoColors.label,
              fontFamily: '.SF Pro Text',
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.label,
                fontFamily: '.SF Pro Text',
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