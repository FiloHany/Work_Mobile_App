import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/correction_request.dart';
import '../providers/corrections_provider.dart';

class CorrectionsHistoryScreen extends ConsumerWidget {
  const CorrectionsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(correctionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Correction History')),
      body: state.isLoading
          ? const AppLoading()
          : state.requests.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.requests.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) =>
                      _RequestTile(request: state.requests[i]),
                ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});
  final CorrectionRequest request;

  Color get _statusColor => switch (request.status) {
        CorrectionStatus.pending => AppColors.warning,
        CorrectionStatus.approved => AppColors.success,
        CorrectionStatus.rejected => AppColors.error,
      };

  IconData get _statusIcon => switch (request.status) {
        CorrectionStatus.pending => Icons.hourglass_empty_outlined,
        CorrectionStatus.approved => Icons.check_circle_outline,
        CorrectionStatus.rejected => Icons.cancel_outlined,
      };

  String get _timeLabel {
    final ci = request.requestedCheckIn;
    final co = request.requestedCheckOut;
    if (ci != null && co != null) {
      return '${_fmt(ci)} → ${_fmt(co)}';
    } else if (ci != null) {
      return 'Check-in: ${_fmt(ci)}';
    } else if (co != null) {
      return 'Check-out: ${_fmt(co)}';
    }
    return '';
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.requestType.label,
                  style: AppTextStyles.labelLarge,
                ),
              ),
              Icon(_statusIcon, color: _statusColor, size: 18),
              const Gap(6),
              Text(
                request.status.label,
                style: AppTextStyles.labelMedium.copyWith(color: _statusColor),
              ),
            ],
          ),
          const Gap(6),
          Text(
            DateFormat('EEE, d MMM yyyy').format(request.targetDate),
            style: AppTextStyles.bodySmall,
          ),
          const Gap(6),
          if (_timeLabel.isNotEmpty) ...[
            Text(_timeLabel,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary)),
            const Gap(4),
          ],
          Text(request.reason, style: AppTextStyles.bodySmall),
          if (request.reviewerNotes != null) ...[
            const Gap(6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Note: ${request.reviewerNotes}',
                  style: AppTextStyles.bodySmall),
            ),
          ],
          if (request.createdAt != null) ...[
            const Gap(4),
            Text(
              'Submitted ${DateFormat('d MMM, HH:mm').format(request.createdAt!)}',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_outlined, size: 56, color: AppColors.textHint),
            const Gap(16),
            const Text('No corrections yet',
                style: AppTextStyles.headlineMedium),
            const Gap(8),
            const Text('Applied corrections will appear here.',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      );
}
