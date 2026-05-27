import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/attendance_provider.dart';

/// Standalone check-in/out screen navigable from deep links or quick actions.
class CheckInOutScreen extends ConsumerStatefulWidget {
  const CheckInOutScreen({super.key});

  @override
  ConsumerState<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends ConsumerState<CheckInOutScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider);
    final isIn = attendance.isCheckedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIn ? 'Check Out' : 'Check In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(isCheckedIn: isIn, session: attendance.activeSession),
            const Gap(32),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_outlined),
                ),
              ),
            ),
            const Gap(32),
            ElevatedButton.icon(
              onPressed: attendance.isCheckingIn || attendance.isCheckingOut
                  ? null
                  : () async {
                      final notes = _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim();
                      bool ok;
                      if (isIn) {
                        ok = await ref
                            .read(attendanceProvider.notifier)
                            .checkOut(notes: notes);
                      } else {
                        ok = await ref
                            .read(attendanceProvider.notifier)
                            .checkIn(notes: notes);
                      }
                      if (ok && context.mounted) context.pop();
                    },
              icon: Icon(isIn ? Icons.logout_rounded : Icons.login_rounded),
              label: Text(isIn ? 'Check Out Now' : 'Check In Now'),
            ),
            if (attendance.error != null) ...[
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  attendance.error!,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isCheckedIn, required this.session});
  final bool isCheckedIn;
  final dynamic session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCheckedIn
            ? AppColors.statusInProgressBg
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isCheckedIn
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color:
                isCheckedIn ? AppColors.statusInProgress : AppColors.textHint,
            size: 28,
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCheckedIn ? 'Currently checked in' : 'Not checked in today',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isCheckedIn
                      ? AppColors.statusInProgress
                      : AppColors.textSecondary,
                ),
              ),
              if (isCheckedIn && session != null)
                Text(
                  'Since ${session.checkInTime.hour.toString().padLeft(2, '0')}:${session.checkInTime.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
