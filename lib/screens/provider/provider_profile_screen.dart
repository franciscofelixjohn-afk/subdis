import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/pages/login_screen.dart';
import '../../widgets/provider_bottom_nav_bar.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  bool _isLoading = true;
  String _fullName = 'Loading...';
  String _experience = '';
  String _categories = '';
  String _rates = '';
  String _email = '';
  String _phone = '';
  String _serviceArea = '';
  String _verificationStatus = 'pending';
  String _resumeUrl = '';

  bool _biometricLogin = true;
  bool _twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _fullName = data['name'] ?? data['fullName'] ?? user.displayName ?? 'No Name Provided';
            _experience = data['experience'] ?? '';
            _categories = data['service'] ?? data['serviceCategory'] ?? 'General Service';
            _rates = data['rates'] ?? '';
            _email = data['email'] ?? user.email ?? '';
            _phone = data['phone'] ?? '';
            _serviceArea = data['serviceArea'] ?? '';
            _verificationStatus = (data['verificationStatus'] ?? 'pending').toString().toLowerCase();
            _resumeUrl = data['validIdUrl'] ?? data['resumeUrl'] ?? '';
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showAccountInformationDialog() {
    final nameController = TextEditingController(text: _fullName);
    final expController = TextEditingController(text: _experience);
    final catController = TextEditingController(text: _categories);
    final rateController = TextEditingController(text: _rates);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final areaController = TextEditingController(text: _serviceArea);
    final resumeController = TextEditingController(text: _resumeUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B192C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: Text(
          'Edit Application & Details',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Full Name', nameController),
                const SizedBox(height: 12),
                _buildTextField('Service Category / Application', catController),
                const SizedBox(height: 12),
                _buildTextField('Experience', expController),
                const SizedBox(height: 12),
                _buildTextField('Service Rates', rateController),
                const SizedBox(height: 12),
                _buildTextField('Resume / Valid ID Link or Filename', resumeController),
                const SizedBox(height: 12),
                _buildTextField('Email Address', emailController),
                const SizedBox(height: 12),
                _buildTextField('Phone Number', phoneController),
                const SizedBox(height: 12),
                _buildTextField('Service Area', areaController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('providers')
                    .doc(user.uid)
                    .update({
                  'name': nameController.text.trim(),
                  'service': catController.text.trim(),
                  'experience': expController.text.trim(),
                  'rates': rateController.text.trim(),
                  'validIdUrl': resumeController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'serviceArea': areaController.text.trim(),
                  'verificationStatus': 'pending',
                });
              }

              if (!context.mounted) return;

              setState(() {
                _fullName = nameController.text.trim();
                _categories = catController.text.trim();
                _experience = expController.text.trim();
                _rates = rateController.text.trim();
                _resumeUrl = resumeController.text.trim();
                _email = emailController.text.trim();
                _phone = phoneController.text.trim();
                _serviceArea = areaController.text.trim();
                _verificationStatus = 'pending';
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application updated & submitted for admin review!'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save & Submit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettingsModal() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF061021),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Security Settings',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF38BDF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField('Current Password', currentPassController, obscure: true),
                const SizedBox(height: 12),
                _buildTextField('New Password', newPassController, obscure: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentPassword = currentPassController.text.trim();
                      final newPassword = newPassController.text.trim();

                      if (currentPassword.isEmpty || newPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in both password fields'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New password must be at least 6 characters'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPassword,
                          );
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newPassword);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update password: ${e.message}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update Password',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(
                    'Biometric Login',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Use fingerprint or Face ID to log in',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                  ),
                  value: _biometricLogin,
                  activeThumbColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setModalState(() => _biometricLogin = val);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Two-Factor Authentication',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Extra security layer for your account',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                  ),
                  value: _twoFactorAuth,
                  activeThumbColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setModalState(() => _twoFactorAuth = val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF38BDF8),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020408),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    final bool isApproved = _verificationStatus == 'approved';

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 4),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020408),
                  Color(0xFF061021),
                  Color(0xFF0B192C),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.15),
                    const Color(0xFF0284C7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider Profile',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isApproved
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isApproved
                              ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF020408),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isApproved
                                    ? Icons.verified_rounded
                                    : Icons.hourglass_top_rounded,
                                color: isApproved
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFFF59E0B),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _fullName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _categories,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isApproved
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isApproved
                                        ? Icons.verified_user_rounded
                                        : Icons.hourglass_empty_rounded,
                                    color: isApproved
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isApproved ? 'Verified Provider' : 'Pending Admin Approval',
                                    style: GoogleFonts.poppins(
                                      color: isApproved
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFFF59E0B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isApproved) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '4.9 Rating',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFF59E0B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Application & Services',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Attach Resume / Service Details',
                    subtitle: 'Tap to update service category, experience, and ID/Resume',
                    onTap: _showAccountInformationDialog,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Settings & Activity',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    icon: Icons.history_rounded,
                    title: 'Job History',
                    subtitle: 'View completed and cancelled jobs',
                    onTap: () {},
                  ),
                  _buildActionTile(
                    icon: Icons.security_outlined,
                    title: 'Security Settings',
                    subtitle: 'Manage password, biometrics, and 2FA',
                    onTap: _showSecuritySettingsModal,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor:
                            Colors.redAccent.withValues(alpha: 0.05),
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}