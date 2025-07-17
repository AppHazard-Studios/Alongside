// lib/widgets/day_selector_widget.dart - SIMPLIFIED VERSION (REPLACE ENTIRE FILE)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/day_selection_data.dart';
import '../utils/colors.dart';

class DaySelectorWidget extends StatefulWidget {
  final DaySelectionData? initialData;
  final Function(DaySelectionData?) onChanged;
  final String reminderTime;

  const DaySelectorWidget({
    Key? key,
    this.initialData,
    required this.onChanged,
    required this.reminderTime,
  }) : super(key: key);

  @override
  State<DaySelectorWidget> createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget> {
  late Set<int> _selectedDays;
  late RepeatInterval _interval;
  int _customDays = 7;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedDays = Set<int>.from(widget.initialData!.selectedDays);
      _interval = widget.initialData!.interval;
      _customDays = widget.initialData!.customIntervalDays;
      _hasReminder = _selectedDays.isNotEmpty;
    } else {
      _selectedDays = {};
      _interval = RepeatInterval.weekly;
      _hasReminder = false;
    }
  }

  void _updateData() {
    if (_hasReminder && _selectedDays.isNotEmpty) {
      widget.onChanged(DaySelectionData(
        selectedDays: _selectedDays,
        interval: _interval,
        customIntervalDays: _customDays,
      ));
    } else {
      widget.onChanged(null);
    }
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
          // Header with reminder toggle
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  color: AppColors.warning,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
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
              CupertinoSwitch(
                value: _hasReminder,
                onChanged: (value) {
                  setState(() {
                    _hasReminder = value;
                    if (!value) {
                      _selectedDays.clear();
                    }
                    _updateData();
                  });
                },
                activeColor: AppColors.warning,
              ),
            ],
          ),

          if (_hasReminder) ...[
            const SizedBox(height: 24),

            // Day selector
            const Text(
              'Select Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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

              // Repeat interval selector
              const Text(
                'Repeat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.bell_fill,
                      color: AppColors.warning,
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
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          Text(
                            'At ${widget.reminderTime}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  Icon(
                    CupertinoIcons.bell_slash,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'No reminders will be sent',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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
          color: isSelected ? AppColors.warning : CupertinoColors.systemGrey6,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.warning : CupertinoColors.systemGrey4,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? CupertinoColors.white : AppColors.textPrimary,
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
        _buildCustomIntervalOption(),
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
          color: isSelected ? AppColors.warning.withOpacity(0.1) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.warning : CupertinoColors.systemGrey5,
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
                  color: isSelected ? AppColors.warning : CupertinoColors.systemGrey3,
                  width: 2,
                ),
                color: isSelected ? AppColors.warning : CupertinoColors.white,
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
                color: isSelected ? AppColors.warning : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIntervalOption() {
    final isSelected = _interval == RepeatInterval.custom;

    return GestureDetector(
      onTap: () {
        setState(() {
          _interval = RepeatInterval.custom;
          _updateData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warning.withOpacity(0.1) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.warning : CupertinoColors.systemGrey5,
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
                  color: isSelected ? AppColors.warning : CupertinoColors.systemGrey3,
                  width: 2,
                ),
                color: isSelected ? AppColors.warning : CupertinoColors.white,
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
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'Every',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    GestureDetector(
                      onTap: () => _showCustomDaysPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _customDays.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'X',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    'days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.warning : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDaysPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateData();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: _customDays - 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _customDays = index + 1;
                  });
                },
                children: List.generate(
                  365,
                      (index) => Center(
                    child: Text(
                      '${index + 1} day${index == 0 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
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
      customIntervalDays: _customDays,
    );

    return data.getDescription();
  }
}