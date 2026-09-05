import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'active_bookings_screen.dart';
import '../../services/notification_service.dart';

class BookingScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String serviceName;
  final String rating;
  final String price;

  const BookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.serviceName,
    required this.rating,
    required this.price,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedDate = 'Select Date';
  String selectedTime = 'Select Time';
  bool isLoading = false;

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedDate = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked.format(context);
      });
    }
  }

Future<void> confirmBooking() async {
  final address = addressController.text.trim();
  final notes = notesController.text.trim();
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logged-in user found.')),
    );
    return;
  }

  if (selectedDate == 'Select Date' || selectedTime == 'Select Time') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select date and time.')),
    );
    return;
  }

  if (address.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter the service address.')),
    );
    return;
  }

  try {
    setState(() {
      isLoading = true;
    });

    final String userId = user.uid;
    final String providerId = widget.providerId;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final String userName = userDoc.data()?['name'] ?? 'Homeowner';

    final bookingRef =
        await FirebaseFirestore.instance.collection('bookings').add({
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'providerName': widget.providerName,
      'serviceName': widget.serviceName,
      'bookingDate': selectedDate,
      'bookingTime': selectedTime,
      'address': address,
      'notes': notes,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await NotificationService().createNotification(
      userId: providerId,
      title: 'New Booking Request',
      body: 'You have a new booking request for ${widget.serviceName}.',
      type: 'booking',
      bookingId: bookingRef.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed successfully.'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveBookingsScreen(),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save booking: $e')),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Book Service',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.handyman_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.providerName,
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.serviceName,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.rating,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.price,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Booking Details',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: pickDate,
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate,
                      style: AppTextStyles.body,
                    ),
                    const Icon(Icons.calendar_today_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: pickTime,
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedTime,
                      style: AppTextStyles.body,
                    ),
                    const Icon(Icons.access_time_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              controller: addressController,
              labelText: 'Address',
              hintText: 'Enter service address',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              controller: notesController,
              labelText: 'Additional Notes',
              hintText: 'Add service details or special requests',
              prefixIcon: Icons.note_alt_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: isLoading ? 'Saving Booking...' : 'Confirm Booking',
              icon: Icons.check_circle_outline,
              onPressed: isLoading ? () {} : confirmBooking,
            ),
          ],
        ),
      ),
    );
  }
}