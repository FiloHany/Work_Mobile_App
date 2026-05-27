import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/onboarding_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserRole _role = UserRole.demonstrator;
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _role = profile.role;
      _facultyCtrl.text = profile.faculty ?? '';
      _employeeIdCtrl.text = profile.employeeId ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _selectedDeptId = profile.departmentId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    _employeeIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(onboardingProvider.notifier).complete(
          fullName: _nameCtrl.text.trim(),
          role: _role,
          departmentId: _selectedDeptId,
          faculty: _facultyCtrl.text.trim().isEmpty
              ? null
              : _facultyCtrl.text.trim(),
          employeeId: _employeeIdCtrl.text.trim().isEmpty
              ? null
              : _employeeIdCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );

    if (ok && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.today);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    ref.listen(onboardingProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: AppColors.background,
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
                const Text('Set up your profile',
                    style: AppTextStyles.headlineLarge),
                const Gap(6),
                const Text(
                    'This information helps personalise your experience.',
                    style: AppTextStyles.bodyLarge),
                const Gap(32),

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Enter your full name'
                      : null,
                ),
                const Gap(16),

                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: UserRole.values
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (r) => setState(() => _role = r!),
                ),
                const Gap(16),

                // Department
                if (state.departments.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeptId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None / Not listed')),
                      ...state.departments.map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          )),
                    ],
                    onChanged: (id) => setState(() => _selectedDeptId = id),
                  ),
                  const Gap(16),
                ],

                TextFormField(
                  controller: _facultyCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Faculty / College',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const Gap(16),

                TextFormField(
                  controller: _employeeIdCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
                const Gap(16),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const Gap(40),

                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: const Text('Complete Setup'),
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
