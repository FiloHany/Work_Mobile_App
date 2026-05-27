import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_session.dart';

final _historyProvider = FutureProvider<List<AttendanceSession>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final repo = ref.read(attendanceRepositoryProvider);
  final cycle = WorkCycleCalculator.currentCycle();
  return repo.fetchSessions(
    userId: userId,
    from: cycle.start,
    to: cycle.end,
  );
});

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('Attendance History'),
            actions: [
              TextButton(
                onPressed: () => context.push(Routes.reports),
                child: const Text('Reports'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: historyAsync.when(
              loading: () => const SliverFillRemaining(child: AppLoading()),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text(e.toString()))),
              data: (sessions) => sessions.isEmpty
                  ? const SliverFillRemaining(child: _EmptyHistory())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _SessionTile(session: sessions[i]),
                        childCount: sessions.length,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final AttendanceSession session;

  Duration? get _roundedDuration {
    final checkout = session.checkOutTime;
    if (checkout == null) return null;
    final effectiveIn = HoursRuleEngine.roundCheckIn(session.checkInTime);
    final effectiveOut = HoursRuleEngine.roundCheckOut(checkout);
    final diff = effectiveOut.difference(effectiveIn);
    return diff.isNegative ? Duration.zero : diff;
  }

  Color get _statusColor => switch (session.status) {
        SessionStatus.active => AppColors.statusInProgress,
        SessionStatus.completed => AppColors.statusValid,
        SessionStatus.voided => AppColors.textHint,
        SessionStatus.correctionApplied => AppColors.warning,
      };

  String get _statusLabel => switch (session.status) {
        SessionStatus.active => 'Active',
        SessionStatus.completed =>
          (_roundedDuration?.inMinutes ?? 0) >= 240 ? 'Valid' : 'Short',
        SessionStatus.voided => 'Voided',
        SessionStatus.correctionApplied => 'Corrected',
      };

  @override
  Widget build(BuildContext context) {
    final duration = _roundedDuration;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, d MMM').format(session.sessionDate),
                style: AppTextStyles.labelLarge,
              ),
              const Gap(2),
              Text(
                '${DateFormat('HH:mm').format(session.checkInTime)} – '
                '${session.checkOutTime != null ? DateFormat('HH:mm').format(session.checkOutTime!) : '—'}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          if (duration != null)
            Text(duration.formatted, style: AppTextStyles.headlineSmall),
          const Gap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTextStyles.labelSmall
                  .copyWith(color: _statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 56, color: AppColors.textHint),
          const Gap(16),
          const Text('No attendance records yet',
              style: AppTextStyles.headlineSmall),
          const Gap(8),
          const Text('Check in to start tracking your hours.',
              style: AppTextStyles.bodyMedium),
        ],
      );
}
