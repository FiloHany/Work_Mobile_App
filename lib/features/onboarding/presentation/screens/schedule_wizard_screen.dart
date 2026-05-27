import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/domain/entities/schedule_entry.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';

// Sat=6, Sun=0, Mon=1, Tue=2, Wed=3, Thu=4
const _workDayIndices = [6, 0, 1, 2, 3, 4];
const _workDayNames = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

class ScheduleWizardScreen extends ConsumerStatefulWidget {
  const ScheduleWizardScreen({super.key});

  @override
  ConsumerState<ScheduleWizardScreen> createState() =>
      _ScheduleWizardScreenState();
}

class _ScheduleWizardScreenState extends ConsumerState<ScheduleWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      context.go(Routes.today);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _addEntry(int dayOfWeek) async {
    final result = await showModalBottomSheet<_EntryData?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EntryFormSheet(),
    );
    if (result == null) return;
    ref.read(scheduleProvider.notifier).addEntry(
          dayOfWeek: dayOfWeek,
          startTime: result.startTime,
          endTime: result.endTime,
          entryType: result.type,
          title: result.title,
          groupName: result.groupName,
          location: result.location,
        );
  }

  @override
  Widget build(BuildContext context) {
    final byDay = ref.watch(scheduleProvider).byDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Weekly Schedule Setup'),
        actions: [
          TextButton(
            onPressed: () => context.go(Routes.today),
            child: const Text('Skip for now'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: List.generate(6, (i) {
                final done = i < _currentPage;
                final active = i == _currentPage;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: done || active
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${_currentPage + 1} of 6',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                ),
                Text(
                  _workDayNames[_currentPage],
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Day pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (_, i) {
                final dow = _workDayIndices[i];
                final entries = (byDay[dow] ?? [])
                    .where((e) => e.entryType != ScheduleEntryType.free)
                    .toList();
                return _DayPage(
                  dayName: _workDayNames[i],
                  entries: entries,
                  onAdd: () => _addEntry(dow),
                );
              },
            ),
          ),

          // Navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                    const Gap(12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_currentPage == 5 ? 'Done' : 'Next →'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day page ──────────────────────────────────────────────────────────────────

class _DayPage extends StatelessWidget {
  const _DayPage({
    required this.dayName,
    required this.entries,
    required this.onAdd,
  });
  final String dayName;
  final List<ScheduleEntry> entries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayName, style: AppTextStyles.displayMedium),
          const Gap(6),
          Text(
            'What are your regular commitments on $dayName?',
            style:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(20),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 52, color: AppColors.textHint),
                        const Gap(12),
                        Text('Nothing added yet',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint)),
                        const Gap(4),
                        Text('Tap the button below to add entries',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  )
                : ListView(
                    children: entries.map((e) => _EntryTile(entry: e)).toList(),
                  ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Entry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          const Gap(4),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final ScheduleEntry entry;

  static Color _dot(ScheduleEntryType t) => switch (t) {
        ScheduleEntryType.lecture => AppColors.primary,
        ScheduleEntryType.section => AppColors.accent,
        ScheduleEntryType.lab => AppColors.warning,
        ScheduleEntryType.meeting => AppColors.info,
        ScheduleEntryType.officeHours => AppColors.success,
        ScheduleEntryType.requiredPresence => AppColors.primaryLight,
        ScheduleEntryType.free => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: _dot(entry.entryType),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTextStyles.labelLarge),
                Text(
                  '${entry.startTime.substring(0, 5)} – ${entry.endTime.substring(0, 5)}  ·  ${entry.entryType.label}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entry form bottom sheet ───────────────────────────────────────────────────

class _EntryData {
  const _EntryData({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.groupName,
    this.location,
  });
  final String title;
  final String startTime;
  final String endTime;
  final ScheduleEntryType type;
  final String? groupName;
  final String? location;
}

class _EntryFormSheet extends StatefulWidget {
  const _EntryFormSheet();

  @override
  State<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<_EntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 30);
  ScheduleEntryType _type = ScheduleEntryType.lecture;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _groupCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    Navigator.pop(
      context,
      _EntryData(
        title: _titleCtrl.text.trim(),
        startTime: _fmt(_start),
        endTime: _fmt(_end),
        type: _type,
        groupName: _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Add Entry', style: AppTextStyles.headlineSmall)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Gap(16),

            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Course code *',
                hintText: 'e.g. AI 102',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const Gap(14),

            Row(
              children: [
                Expanded(child: _TimeTile(label: 'Start', time: _start, onTap: _pickStart)),
                const Gap(12),
                Expanded(child: _TimeTile(label: 'End', time: _end, onTap: _pickEnd)),
              ],
            ),
            const Gap(14),

            DropdownButtonFormField<ScheduleEntryType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ScheduleEntryType.values
                  .where((t) => t != ScheduleEntryType.free)
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(14),

            TextFormField(
              controller: _groupCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Group (optional)',
                hintText: 'e.g. A9 or B2-AI',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
            const Gap(14),

            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Hall / Room (optional)',
                hintText: 'e.g. E 117',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const Gap(24),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile(
      {required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const Gap(4),
              Text(time.format(context), style: AppTextStyles.labelLarge),
            ],
          ),
        ),
      );
}
