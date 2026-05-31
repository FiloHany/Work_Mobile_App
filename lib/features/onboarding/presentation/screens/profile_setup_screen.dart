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

// ── CS & AI Faculty constants ─────────────────────────────────────────────────

const _facultyName = 'Faculty of Computer Science & AI';

const _fallbackDepartments = [
  'Artificial Intelligence',
  'Computer Science',
  'Data Science',
  'Cyber Security',
];

const _roleInfo = {
  UserRole.demonstrator: (
    icon: Icons.terminal_rounded,
    color: Color(0xFF2979FF),
    label: 'Demonstrator',
    arabicLabel: 'معيد',
    description: 'Practical labs & tutorials',
  ),
  UserRole.teachingAssistant: (
    icon: Icons.menu_book_rounded,
    color: Color(0xFF00897B),
    label: 'Teaching Assistant',
    arabicLabel: 'مساعد تدريس',
    description: 'Lectures & academic supervision',
  ),
  UserRole.doctor: (
    icon: Icons.science_rounded,
    color: Color(0xFF7B1FA2),
    label: 'Doctor',
    arabicLabel: 'دكتور',
    description: 'Research & faculty member',
  ),
};

// Work-week days the user can choose as an extra rest day (Friday always off).
const _selectableDays = [
  (label: 'Sun', weekday: DateTime.sunday),
  (label: 'Mon', weekday: DateTime.monday),
  (label: 'Tue', weekday: DateTime.tuesday),
  (label: 'Wed', weekday: DateTime.wednesday),
  (label: 'Thu', weekday: DateTime.thursday),
  (label: 'Sat', weekday: DateTime.saturday),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _idCtrl    = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserRole _role           = UserRole.demonstrator;
  String?  _selectedDeptId;
  String?  _selectedDeptLabel; // shown when using fallback list
  final Set<int> _restDays = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));

    final profile = ref.read(profileProvider);
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _role           = profile.role;
      _idCtrl.text    = profile.employeeId ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _selectedDeptId = profile.departmentId;
      _restDays
        ..clear()
        ..addAll(profile.restDays);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(onboardingProvider.notifier).complete(
          fullName:     _nameCtrl.text.trim(),
          role:         _role,
          departmentId: _selectedDeptId,
          faculty:      _facultyName,
          employeeId:   _idCtrl.text.trim().isEmpty ? null : _idCtrl.text.trim(),
          phone:        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          restDays:     _restDays.toList(),
        );

    if (ok && mounted) {
      context.canPop() ? context.pop() : context.go(Routes.today);
    }
  }

  String get _initials {
    final parts = _nameCtrl.text.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
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

    // Always use the hardcoded faculty departments — the 4 departments
    // are fixed for this faculty and should not change with DB data.
    final deptOptions = _fallbackDepartments
        .map((name) => (id: null as String?, name: name))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // ── Gradient hero header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProfileHero(
                  initials: _initials,
                  canPop: context.canPop(),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Personal information ─────────────────────────────────
                    _SectionLabel('Personal Information'),
                    const Gap(10),
                    _Card(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.bodyMedium,
                            decoration: _inputDeco(
                              label: 'Full Name',
                              hint: 'e.g. Ahmed Mohamed Hassan',
                              icon: Icons.person_outline_rounded,
                              required: true,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Enter your full name'
                                : null,
                          ),
                          const _FieldDivider(),
                          TextFormField(
                            controller: _idCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco(
                              label: 'Employee ID',
                              hint: 'Optional',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          const _FieldDivider(),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDeco(
                              label: 'Phone Number',
                              hint: 'Optional',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // ── Academic role ────────────────────────────────────────
                    _SectionLabel('Academic Role'),
                    const Gap(10),
                    Row(
                      children: UserRole.values.map((role) {
                        final info = _roleInfo[role]!;
                        final selected = _role == role;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: role != UserRole.doctor ? 8 : 0,
                            ),
                            child: _RoleCard(
                              icon: info.icon,
                              color: info.color,
                              label: info.label,
                              arabicLabel: info.arabicLabel,
                              description: info.description,
                              selected: selected,
                              onTap: () => setState(() => _role = role),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(24),

                    // ── Department ───────────────────────────────────────────
                    _SectionLabel('Department'),
                    const Gap(10),
                    _Card(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: deptOptions.map((dept) {
                          final isSelected = dept.id != null
                              ? _selectedDeptId == dept.id
                              : _selectedDeptLabel == dept.name;
                          return _DeptChip(
                            label: dept.name,
                            selected: isSelected,
                            onTap: () => setState(() {
                              _selectedDeptId    = dept.id;
                              _selectedDeptLabel = dept.name;
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(24),

                    // ── Extra rest day ───────────────────────────────────────
                    _SectionLabel('Extra Rest Day'),
                    const Gap(4),
                    Text(
                      'Friday is always off. Add one more rest day if applicable.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Gap(10),
                    _Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _selectableDays.map((day) {
                          final on = _restDays.contains(day.weekday);
                          return _DayToggle(
                            label: day.label,
                            on: on,
                            onTap: () => setState(() {
                              if (on) {
                                _restDays.remove(day.weekday);
                              } else {
                                _restDays
                                  ..clear() // only one extra rest day
                                  ..add(day.weekday);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(32),

                    // ── Save button ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.initials, required this.canPop});
  final String initials;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF0A1E3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          if (canPop) const Gap(16),

          // Avatar + faculty info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: initials.isEmpty
                      ? const Icon(Icons.person_rounded,
                          color: Colors.white, size: 32)
                      : Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Faculty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded,
                              color: Colors.white, size: 12),
                          const Gap(5),
                          const Flexible(
                            child: Text(
                              'Faculty of CS & AI',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Staff Profile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Set up your account to get personalised\nwork-hour tracking.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.arabicLabel,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String arabicLabel;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: selected ? color : AppColors.textHint, size: 20),
            ),
            const Gap(8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const Gap(2),
            Text(
              arabicLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: selected
                    ? color.withValues(alpha: 0.8)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Department chip ───────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  const _DeptChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded,
                    size: 13, color: AppColors.primary),
                const Gap(5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Day toggle ────────────────────────────────────────────────────────────────

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.on,
    required this.onTap,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on
                ? AppColors.primary
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: on ? Colors.white : AppColors.textHint,
                ),
              ),
              const Gap(4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.divider,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTextStyles.captionUppercase,
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: child,
      );
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
      );
}

InputDecoration _inputDeco({
  required String label,
  String? hint,
  required IconData icon,
  bool required = false,
}) =>
    InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
    );
