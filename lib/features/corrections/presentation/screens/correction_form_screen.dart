import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../domain/entities/correction_request.dart';
import '../providers/corrections_provider.dart';

class CorrectionFormScreen extends ConsumerStatefulWidget {
  const CorrectionFormScreen({super.key});

  @override
  ConsumerState<CorrectionFormScreen> createState() =>
      _CorrectionFormScreenState();
}

class _CorrectionFormScreenState extends ConsumerState<CorrectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _targetDate = DateTime.now();
  CorrectionType _type = CorrectionType.missedCheckIn;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final initial = isCheckIn
        ? (_checkInTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_checkOutTime ?? const TimeOfDay(hour: 15, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    // For today's date, reject times that are more than 5 minutes in the future.
    final now = DateTime.now();
    final isToday = _targetDate.year == now.year &&
        _targetDate.month == now.month &&
        _targetDate.day == now.day;
    if (isToday) {
      final pickedDt = DateTime(
          now.year, now.month, now.day, picked.hour, picked.minute);
      if (pickedDt.isAfter(now.add(const Duration(minutes: 5)))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cannot select a future time for today.')),
          );
        }
        return;
      }
    }

    setState(() {
      if (isCheckIn) {
        _checkInTime = picked;
      } else {
        _checkOutTime = picked;
      }
    });
  }

  DateTime? _buildDateTime(TimeOfDay? time) {
    if (time == null) return null;
    return DateTime(_targetDate.year, _targetDate.month, _targetDate.day,
        time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == CorrectionType.fullCorrection &&
        (_checkInTime == null || _checkOutTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide both check-in and check-out times')),
      );
      return;
    }

    final ok = await ref.read(correctionsProvider.notifier).apply(
          targetDate: _targetDate,
          requestType: _type,
          reason: '',
          requestedCheckIn: _type != CorrectionType.missedCheckOut
              ? _buildDateTime(_checkInTime)
              : null,
          requestedCheckOut: _type != CorrectionType.missedCheckIn
              ? _buildDateTime(_checkOutTime)
              : null,
        );

    if (ok && mounted) {
      if (_type == CorrectionType.missedCheckIn) {
        await ref.read(attendanceProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Correction applied — timer is now running')),
          );
          context.go(Routes.today);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correction applied successfully')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(correctionsProvider);

    ref.listen(correctionsProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final showCheckIn = _type != CorrectionType.missedCheckOut;
    final showCheckOut = _type != CorrectionType.missedCheckIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Correction Request')),
      body: AppLoadingOverlay(
        isLoading: state.isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apply a correction',
                    style: AppTextStyles.headlineLarge),
                const Gap(6),
                const Text(
                  'Fix a missed check-in or check-out. Changes are applied immediately.',
                  style: AppTextStyles.bodyLarge,
                ),
                const Gap(32),

                // Target date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
                const Gap(16),

                // Request type
                DropdownButtonFormField<CorrectionType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Correction type *',
                    prefixIcon: Icon(Icons.tune_outlined),
                  ),
                  items: CorrectionType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t!),
                ),
                const Gap(16),

                // Times
                if (showCheckIn) ...[
                  InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Check-in time',
                        prefixIcon: Icon(Icons.login_outlined),
                      ),
                      child: Text(
                        _checkInTime != null
                            ? '${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _checkInTime == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                ],

                if (showCheckOut) ...[
                  InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Check-out time',
                        prefixIcon: Icon(Icons.logout_outlined),
                      ),
                      child: Text(
                        _checkOutTime != null
                            ? '${_checkOutTime!.hour.toString().padLeft(2, '0')}:${_checkOutTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _checkOutTime == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                ],

                const Gap(16),

                ElevatedButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  child: const Text('Apply Correction'),
                ),
                const Gap(16),
                OutlinedButton(
                  onPressed: () => context.push('/corrections/history'),
                  child: const Text('View Correction History'),
                ),
                const Gap(32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
