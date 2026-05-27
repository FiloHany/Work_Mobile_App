import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/auth_provider.dart';

/// Registration screen — users enter their name and role only.
/// Email and password are auto-generated and never shown.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// Selectable extra rest days (Friday=5 is always off — not shown here).
const _extraRestOptions = [
  (label: 'Sat', value: DateTime.saturday),
  (label: 'Sun', value: DateTime.sunday),
  (label: 'Mon', value: DateTime.monday),
  (label: 'Tue', value: DateTime.tuesday),
  (label: 'Wed', value: DateTime.wednesday),
  (label: 'Thu', value: DateTime.thursday),
];

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  UserRole _role = UserRole.demonstrator;
  final List<int> _restDays = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authProvider.notifier).registerByName(
          fullName: _nameCtrl.text.trim(),
          role: _role,
          restDays: List.of(_restDays),
        );

    if (ok && mounted) context.go(Routes.scheduleWizard);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: auth.isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(56),
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const Gap(24),
                  const Text('Get Started', style: AppTextStyles.displayMedium),
                  const Gap(6),
                  Text(
                    'Enter your name to begin tracking your work hours.',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const Gap(40),

                  // Name field
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'e.g. Ahmed Mohamed',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Enter your full name (at least 2 characters)';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),

                  // Role picker
                  DropdownButtonFormField<UserRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ))
                        .toList(),
                    onChanged: auth.isLoading
                        ? null
                        : (r) => setState(() => _role = r!),
                  ),
                  const Gap(20),

                  // Extra rest days — multi-select chips (Friday always off)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.weekend_outlined,
                              size: 20, color: AppColors.textSecondary),
                          const Gap(8),
                          Text(
                            'Additional rest days (optional)',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        'Friday is always off. Select any other days.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                      ),
                      const Gap(10),
                      Wrap(
                        spacing: 8,
                        children: _extraRestOptions.map((o) {
                          final selected = _restDays.contains(o.value);
                          return FilterChip(
                            label: Text(o.label),
                            selected: selected,
                            onSelected: auth.isLoading
                                ? null
                                : (_) => setState(() {
                                      if (selected) {
                                        _restDays.remove(o.value);
                                      } else {
                                        _restDays.add(o.value);
                                      }
                                    }),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: AppTextStyles.labelSmall.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Gap(36),

                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: const Text('Start Tracking'),
                  ),
                  const Gap(24),

                  Center(
                    child: Text(
                      'Your name must be unique — it is how you are identified.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
