import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';

enum _ProfileMode { view, edit, password }

class ProfileModulePage extends ConsumerStatefulWidget {
  const ProfileModulePage({super.key});

  @override
  ConsumerState<ProfileModulePage> createState() => _ProfileModulePageState();
}

class _ProfileModulePageState extends ConsumerState<ProfileModulePage> {
  _ProfileMode _mode = _ProfileMode.view;
  bool _loading = true;
  bool _saving = false;

  String _username = 'User';
  String _biodata = 'No bio added yet.';

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentFirebaseUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final profile = await repo.fetchUserProfile(user.uid);
      if (!mounted) return;
      setState(() {
        _username = (profile?.username.isNotEmpty ?? false)
            ? profile!.username
            : 'User';
        _biodata = (profile?.biodata.isNotEmpty ?? false)
            ? profile!.biodata
            : 'No bio added yet.';
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showEduSnackBar(context, 'Failed to load profile: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    final newName = _nameCtrl.text.trim();
    final newBio = _bioCtrl.text.trim();
    if (newName.isEmpty) {
      showEduSnackBar(context, 'Name cannot be empty');
      return;
    }

    final uid = ref.read(authRepositoryProvider).currentFirebaseUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            uid: uid,
            username: newName,
            biodata: newBio,
          );
      if (!mounted) return;
      setState(() {
        _username = newName;
        _biodata = newBio.isEmpty ? 'No bio added yet.' : newBio;
        _mode = _ProfileMode.view;
      });
      showEduSnackBar(context, 'Updated Successfully');
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updatePassword() async {
    final oldPass = _oldPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    if (oldPass.isEmpty || newPass.isEmpty) {
      showEduSnackBar(context, 'Please fill both fields');
      return;
    }
    if (newPass.length < 6) {
      showEduSnackBar(context, 'New password must be at least 6 characters');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changeAppPassword(
            currentPassword: oldPass,
            newPassword: newPass,
          );
      if (!mounted) return;
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      setState(() => _mode = _ProfileMode.view);
      showEduSnackBar(context, 'Password updated successfully!');
    } catch (e) {
      if (mounted) {
        showEduSnackBar(
          context,
          e.toString().contains('wrong-password') ||
                  e.toString().contains('invalid-credential')
              ? 'Current password does not match.'
              : 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleBack() {
    if (_mode == _ProfileMode.view) {
      Navigator.of(context).pop();
    } else {
      setState(() => _mode = _ProfileMode.view);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mode == _ProfileMode.view,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _mode != _ProfileMode.view) {
          setState(() => _mode = _ProfileMode.view);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EduBackHeader(title: 'My Profile', onBack: _handleBack),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_mode == _ProfileMode.view)
                  _buildViewCard()
                else if (_mode == _ProfileMode.edit)
                  _buildEditCard()
                else
                  _buildPasswordCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewCard() {
    return EduCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Display Name'),
          const SizedBox(height: 6),
          Text(
            _username,
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Biodata'),
          const SizedBox(height: 6),
          Text(
            _biodata,
            style: const TextStyle(fontSize: 15, color: AppColors.textSlate),
          ),
          const SizedBox(height: 28),
          EduButton(
            label: 'Edit Profile',
            backgroundColor: AppColors.primaryBlue,
            borderRadius: 12,
            onPressed: () {
              _nameCtrl.text = _username;
              _bioCtrl.text = _biodata;
              setState(() => _mode = _ProfileMode.edit);
            },
          ),
          const SizedBox(height: 12),
          EduButton(
            label: 'Change App Password',
            backgroundColor: AppColors.primaryPurple,
            borderRadius: 12,
            onPressed: () => setState(() => _mode = _ProfileMode.password),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return EduCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _sectionLabel('New Display Name'),
          const SizedBox(height: 6),
          EduTextField(controller: _nameCtrl, hintText: 'Display Name'),
          const SizedBox(height: 16),
          _sectionLabel('Biodata / About Me'),
          const SizedBox(height: 6),
          EduTextField(
            controller: _bioCtrl,
            hintText: 'Tell others about yourself...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          EduButton(
            label: 'Update Name & Bio',
            backgroundColor: AppColors.tealGreen,
            borderRadius: 12,
            isLoading: _saving,
            onPressed: _updateProfile,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _mode = _ProfileMode.view),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return EduCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Update App Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _sectionLabel('Current App Password'),
          const SizedBox(height: 6),
          EduTextField(
            controller: _oldPassCtrl,
            hintText: 'Enter current password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _sectionLabel('New App Password'),
          const SizedBox(height: 6),
          EduTextField(
            controller: _newPassCtrl,
            hintText: 'Enter new password',
            obscureText: true,
          ),
          const SizedBox(height: 20),
          EduButton(
            label: 'Update Password',
            backgroundColor: AppColors.primaryPurple,
            borderRadius: 12,
            isLoading: _saving,
            onPressed: _updatePassword,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving
                ? null
                : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _mode = _ProfileMode.view),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
      ),
    );
  }
}
