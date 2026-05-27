import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/schedule_provider.dart';

const _dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

class ScheduleEditorScreen extends ConsumerStatefulWidget {
  const ScheduleEditorScreen({super.key, this.entryId});
  final String? entryId;

  @override
  ConsumerState<ScheduleEditorScreen> createState() =>
      _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends ConsumerState<ScheduleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  int _dayOfWeek = 6; // Saturday
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  ScheduleEntryType _type = ScheduleEntryType.lecture;

  ScheduleEntry? _editing;
  bool _populated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_populated) {
      _populate();
      _populated = true;
    }
  }

  void _populate() {
    if (widget.entryId == null) return;
    final entries = ref.read(scheduleProvider).entries;
    final entry = entries.where((e) => e.id == widget.entryId).firstOrNull;
    if (entry == null) return;
    _editing = entry;
    _titleCtrl.text = entry.title;
    _groupCtrl.text = entry.groupName ?? '';
    _locationCtrl.text = entry.location ?? '';
    _dayOfWeek = entry.dayOfWeek;
    _type = entry.entryType;
    final sp = entry.startTime.split(':');
    final ep = entry.endTime.split(':');
    _startTime = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
    _endTime = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _groupCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final notifier = ref.read(scheduleProvider.notifier);
    final group =
        _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim();
    final loc =
        _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim();
    bool ok;

    if (_editing != null) {
      ok = await notifier.updateEntry(_editing!.copyWith(
        dayOfWeek: _dayOfWeek,
        startTime: _fmtTime(_startTime),
        endTime: _fmtTime(_endTime),
        entryType: _type,
        title: _titleCtrl.text.trim(),
        groupName: group,
        location: loc,
      ));
    } else {
      ok = await notifier.addEntry(
        dayOfWeek: _dayOfWeek,
        startTime: _fmtTime(_startTime),
        endTime: _fmtTime(_endTime),
        entryType: _type,
        title: _titleCtrl.text.trim(),
        groupName: group,
        location: loc,
      );
    }

    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'Add Entry' : 'Edit Entry'),
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Gap(16),

                // Day selector
                DropdownButtonFormField<int>(
                  initialValue: _dayOfWeek,
                  decoration: const InputDecoration(
                    labelText: 'Day of week',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: [6, 0, 1, 2, 3, 4]
                      .map((i) => DropdownMenuItem(
                          value: i, child: Text(_dayNames[i])))
                      .toList(),
                  onChanged: (v) => setState(() => _dayOfWeek = v!),
                ),
                const Gap(16),

                // Type selector
                DropdownButtonFormField<ScheduleEntryType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ScheduleEntryType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t!),
                ),
                const Gap(16),

                // Time row
                Row(
                  children: [
                    Expanded(
                      child: _TimePicker(
                        label: 'Start time',
                        time: _startTime,
                        onTap: () => _pickTime(true),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _TimePicker(
                        label: 'End time',
                        time: _endTime,
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                TextFormField(
                  controller: _groupCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Group (optional)',
                    hintText: 'e.g. A9 or B2-AI',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const Gap(16),

                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hall / Room (optional)',
                    hintText: 'e.g. E 117',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const Gap(32),

                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: Text(_editing == null ? 'Add Entry' : 'Save Changes'),
                ),
                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_outlined),
        ),
        child: Text(formatted, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
