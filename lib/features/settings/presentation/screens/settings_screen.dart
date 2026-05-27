import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/semester_mode.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Gap(8),
                // Profile card
                _ProfileCard(
                  name: profile?.fullName ?? '—',
                  role: profile?.role.label ?? '—',
                ),
                const Gap(20),

                // Account
                const _SectionLabel('Account'),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => context.push(Routes.profileSetup),
                ),
                const Gap(16),

                // App
                const _SectionLabel('App'),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Preferences',
                  onTap: () => context.push(Routes.notifications),
                ),
                _SettingsTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'My Schedule',
                  onTap: () => context.push(Routes.schedule),
                ),
                _SettingsTile(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: 'Work Optimizer',
                  onTap: () => context.push(Routes.optimizer),
                ),
                _SettingsTile(
                  icon: Icons.history_outlined,
                  title: 'Attendance History',
                  onTap: () => context.go(Routes.history),
                ),
                _SettingsTile(
                  icon: Icons.celebration_outlined,
                  title: 'Public Holidays',
                  onTap: () => context.push(Routes.holidays),
                ),
                const Gap(16),

                // Semester mode
                const _SectionLabel('Semester Mode'),
                const _SemesterModePicker(),
                const Gap(16),

                // Help
                const _SectionLabel('Help'),
                _SettingsTile(
                  icon: Icons.edit_note_outlined,
                  title: 'Correction Requests',
                  onTap: () => context.push(Routes.correctionsHistory),
                ),
                const Gap(16),

                // Sign out
                _SignOutTile(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                            'You will be returned to the login screen.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text('Sign Out',
                                  style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      // Defer sign-out by one frame so the dialog dismiss
                      // animation's setState calls complete first.
                      // Without this, the GoRouter redirect triggered by
                      // _AuthRefreshNotifier fires while _debugLocked = true.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(authProvider.notifier).signOut();
                      });
                    }
                  },
                ),
                const Gap(32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const Gap(2),
                  Text(role,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xCCFFFFFF),
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SemesterModePicker extends ConsumerWidget {
  const _SemesterModePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(semesterModeProvider).maybeWhen(
          data: (m) => m,
          orElse: () => SemesterMode.semester,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: SemesterMode.values.map((mode) {
          final isLast = mode == SemesterMode.values.last;
          final selected = current == mode;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  mode.icon,
                  color: selected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
                title: Text(mode.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    )),
                subtitle: Text(mode.subtitle,
                    style: AppTextStyles.bodySmall),
                trailing: selected
                    ? Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20)
                    : const Icon(Icons.circle_outlined,
                        color: AppColors.textHint, size: 20),
                onTap: () =>
                    ref.read(semesterModeProvider.notifier).setMode(mode),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(), style: AppTextStyles.captionUppercase),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary, size: 22),
          title: Text(title, style: AppTextStyles.bodyMedium),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textHint, size: 20),
          onTap: onTap,
        ),
      );
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          leading: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 22),
          title: Text('Sign Out',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          onTap: onTap,
        ),
      );
}
