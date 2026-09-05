import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController idImageController = TextEditingController();

  String selectedRole = 'Homeowner';
  String selectedCategory = 'Plumbing';
  bool isLoading = false;

  // --- ERROR STATES ---
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? addressError;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    idImageController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      addressError = null;
    });

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final address = addressController.text.trim();
    final idImage = idImageController.text.trim();

    bool hasError = false;

    // 1. Full Name Validation
    if (fullName.isEmpty) {
      setState(() => nameError = 'Full name is required.');
      hasError = true;
    }

    // 2. Homeowner Address Validation
    if (selectedRole == 'Homeowner' && address.isEmpty) {
      setState(() => addressError = 'Subdivision address (Phase/Block/Lot) is required.');
      hasError = true;
    }

    // 3. Email Validation
    if (email.isEmpty) {
      setState(() => emailError = 'Email address is required.');
      hasError = true;
    } else {
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        setState(() => emailError = 'Invalid email (e.g., name@gmail.com).');
        hasError = true;
      }
    }

    // 4. Password Validation
    if (password.isEmpty) {
      setState(() => passwordError = 'Password is required.');
      hasError = true;
    } else {
      if (password.length < 6) {
        setState(() => passwordError = 'Must be at least 6 characters.');
        hasError = true;
      } else if (!RegExp(r'(?=.*[0-9])').hasMatch(password)) {
        setState(() => passwordError = 'Must contain at least one number.');
        hasError = true;
      } else if (!RegExp(r'(?=.*[.,!@#\$&*~])').hasMatch(password)) {
        setState(() => passwordError = 'Must contain a dot (.) or special char.');
        hasError = true;
      }
    }

    // 5. Confirm Password Validation
    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = 'Please confirm your password.');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => confirmPasswordError = 'Passwords do not match.');
      hasError = true;
    }

    if (hasError) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Firebase Authentication Creation
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Send Email Verification
        await user.sendEmailVerification();

        final String uid = user.uid;
        final now = FieldValue.serverTimestamp();

        if (selectedRole == 'Homeowner') {
          // Save to users collection with address
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fullName': fullName,
            'email': email,
            'role': selectedRole,
            'address': address,
            'createdAt': now,
          });
        } else {
          // Save to providers collection with category, status, and valid ID/picture reference
          await FirebaseFirestore.instance.collection('providers').doc(uid).set({
            'name': fullName,
            'fullName': fullName,
            'email': email,
            'service': selectedCategory,
            'serviceType': selectedCategory,
            'validIdUrl': idImage.isEmpty ? 'demo_valid_id.jpg' : idImage,
            'selfieUrl': 'demo_selfie.jpg',
            'verificationStatus': 'pending', // Pending for admin approval
            'submittedAt': now,
            'createdAt': now,
          });

          // Also save base profile in users collection for role tracking
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fullName': fullName,
            'email': email,
            'role': selectedRole,
            'createdAt': now,
          });
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registration successful! Please check your email for verification before logging in.'),
          duration: Duration(seconds: 5),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() => emailError = 'That email is already in use.');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          horizontal: 28,
                          vertical: 20,
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
                              'Create Account',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Register to start using SubdiServe',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: fullNameController,
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icons.person_outline,
                              errorText: nameError,
                            ),
                            const SizedBox(height: 10),

                            // Role Selection Dropdown
                            Text(
                              'Role',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Homeowner',
                                      child: Text('Homeowner'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Service Provider',
                                      child: Text('Service Provider'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedRole = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Conditional Field: Address if Homeowner, Category & ID Image if Service Provider
                            if (selectedRole == 'Homeowner') ...[
                              CustomTextField(
                                controller: addressController,
                                labelText: 'Subdivision Address',
                                hintText: 'Phase, Block, Lot',
                                prefixIcon: Icons.home_outlined,
                                errorText: addressError,
                              ),
                              const SizedBox(height: 10),
                            ] else ...[
                              Text(
                                'Service Category',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Plumbing',
                                          child: Text('Plumbing')),
                                      DropdownMenuItem(
                                          value: 'Cleaning',
                                          child: Text('Cleaning')),
                                      DropdownMenuItem(
                                          value: 'Electrical',
                                          child: Text('Electrical')),
                                      DropdownMenuItem(
                                          value: 'Nail Care',
                                          child: Text('Nail Care')),
                                      DropdownMenuItem(
                                          value: 'Repair',
                                          child: Text('Repair')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedCategory = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: idImageController,
                                labelText: 'Valid ID / Picture URL or File Name',
                                hintText: 'e.g. valid_id_sample.jpg',
                                prefixIcon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 10),
                            ],

                            CustomTextField(
                              controller: emailController,
                              labelText: 'Email',
                              hintText: 'residence@gmail.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              errorText: emailError,
                            ),
                            const SizedBox(height: 10),
                            CustomTextField(
                              controller: passwordController,
                              labelText: 'Password',
                              hintText: '••••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              errorText: passwordError,
                            ),
                            const SizedBox(height: 10),
                            CustomTextField(
                              controller: confirmPasswordController,
                              labelText: 'Confirm Password',
                              hintText: '••••••••••••',
                              prefixIcon: Icons.lock_reset_outlined,
                              obscureText: true,
                              errorText: confirmPasswordError,
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: isLoading ? 'Registering...' : 'Register',
                              icon: Icons.person_add_alt_1,
                              onPressed: isLoading ? () {} : handleRegister,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Already have an account? Login',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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