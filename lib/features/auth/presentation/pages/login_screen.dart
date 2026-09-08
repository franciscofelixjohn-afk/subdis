import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../screens/admin/admin_dashboard_screen.dart';
import '../../../../screens/homeowner/home_screen.dart';
import '../../../../screens/provider/provider_dashboard_screen.dart';
import '../../../../services/suspension_service.dart';
import 'register_screen.dart';
import 'suspended_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => emailError = 'Email address is required.');
      hasError = true;
    } else {
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        setState(() => emailError = 'Invalid email format.');
        hasError = true;
      }
    }

    if (password.isEmpty) {
      setState(() => passwordError = 'Password is required.');
      hasError = true;
    }

    if (hasError) return;

    try {
      setState(() {
        isLoading = true;
      });

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found.')),
        );
        return;
      }

      final data = userDoc.data();
      final role = (data?['role'] ?? '').toString().toLowerCase();

      // --- Suspension check ---
      // Auto-lifts a timed (3-day / 7-day) suspension if it has already
      // expired; otherwise returns the current (possibly still-suspended)
      // account data.
      final refreshedData =
          await SuspensionService().checkAndAutoLift(uid) ?? data;
      final accountStatus =
          (refreshedData?['status'] ?? 'Active').toString();

      if (accountStatus == 'Suspended') {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuspendedAccountScreen(
              userId: uid,
              userName: (refreshedData?['fullName'] ??
                      refreshedData?['name'] ??
                      'User')
                  .toString(),
              reason: (refreshedData?['suspensionReason'] ?? '').toString(),
              appealStatus:
                  (refreshedData?['appealStatus'] ?? 'none').toString(),
            ),
          ),
        );
        return;
      }

      if (accountStatus == 'Restricted') {
        final endTimestamp = refreshedData?['restrictionEndDate'];
        final endDate =
            endTimestamp is Timestamp ? endTimestamp.toDate() : null;
        final reason = (refreshedData?['suspensionReason'] ?? '').toString();
        final initialAppealStatus =
            (refreshedData?['appealStatus'] ?? 'none').toString();

        if (mounted) {
          final appealController = TextEditingController();
          bool showAppealForm = false;
          bool isSubmitting = false;
          String appealStatus = initialAppealStatus;

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  Future<void> sendAppeal() async {
                    if (appealController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Please explain your appeal.')),
                      );
                      return;
                    }

                    setDialogState(() => isSubmitting = true);
                    try {
                      await SuspensionService().submitAppeal(
                        userId: uid,
                        message: appealController.text,
                        accountStatusAtSubmission: 'Restricted',
                      );
                      setDialogState(() {
                        isSubmitting = false;
                        showAppealForm = false;
                        appealStatus = 'pending';
                      });
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Failed to submit: $e')),
                        );
                      }
                    }
                  }

                  if (showAppealForm) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Submit Appeal',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      content: TextField(
                        controller: appealController,
                        maxLines: 4,
                        autofocus: true,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Explain why your restriction should be lifted...',
                          hintStyle:
                              GoogleFonts.poppins(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () =>
                                  setDialogState(() => showAppealForm = false),
                          child: Text('Back',
                              style:
                                  GoogleFonts.poppins(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : sendAppeal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text('Send',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );
                  }

                  return AlertDialog(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text('Account Restricted',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reason.isNotEmpty) ...[
                          Text('Reason: $reason',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          endDate != null
                              ? 'Your account is restricted until ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}. You can still use your account, but it will automatically become fully suspended if you don\'t appeal in time.'
                              : 'Your account is currently restricted. You can still use your account, but it will automatically become fully suspended if you don\'t appeal in time.',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 12),
                        ),
                        if (appealStatus == 'pending') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Your appeal has been submitted and is awaiting admin review.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      if (appealStatus != 'pending')
                        TextButton(
                          onPressed: () =>
                              setDialogState(() => showAppealForm = true),
                          child: Text('Submit Appeal',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black),
                        child: const Text('Continue'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      }

      if (accountStatus == 'Active') {
        final activationNote =
            (refreshedData?['lastActivationNote'] ?? '').toString();
        final noteAlreadySeen = refreshedData?['lastActivationNoteSeen'];

        if (activationNote.isNotEmpty && noteAlreadySeen == false) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text('Account Reactivated',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                content: Text(
                  'A note from the admin:\n\n"$activationNote"',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          }
          await SuspensionService().markActivationNoteSeen(uid);
        }
      }

      Widget destination;

      if (role == 'homeowner') {
        destination = const HomeownerHomeScreen();
      } else if (role == 'provider') {
        destination = const ProviderDashboardScreen();
      } else if (role == 'admin') {
        destination = const AdminDashboardScreen();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user role.')),
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        setState(() {
          emailError = 'Invalid email or password.';
          passwordError = 'Invalid email or password.';
        });
      } else if (e.code == 'wrong-password') {
        setState(() => passwordError = 'Incorrect password.');
      } else if (e.code == 'invalid-email') {
        setState(() => emailError = 'Invalid email address.');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.22),
                    const Color(0xFF0284C7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    const Color(0xFF38BDF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              blurRadius: 35,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SubdiServe',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exclusive Subdivision Community Portal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 60,
                              offset: const Offset(0, 22),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Access Your Portal',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in securely to manage your services and community requests',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: emailController,
                              labelText: 'Email Address',
                              hintText: 'residence@subdiserve.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              errorText: emailError,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: passwordController,
                              labelText: 'Password',
                              hintText: '••••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              errorText: passwordError,
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: isLoading ? 'Signing in...' : 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: isLoading ? () {} : handleLogin,
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Create an account',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF0284C7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}