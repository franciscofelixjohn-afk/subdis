import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/report_service.dart';
import '../../widgets/progress_timeline.dart';

/// Lets a homeowner see the day-by-day progress (photos + notes) that a
/// provider has posted for a booking, and report the provider to admin
/// if something goes wrong.
class BookingProgressScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String service;
  final String status;

  const BookingProgressScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.status,
  });

  @override
  State<BookingProgressScreen> createState() => _BookingProgressScreenState();
}

class _BookingProgressScreenState extends State<BookingProgressScreen> {
  final ReportService _reportService = ReportService();

  final List<String> _reasons = const [
    'No-show / did not arrive',
    'Poor quality of work',
    'Unsafe or unprofessional behavior',
    'Overcharging / payment issue',
    'Other',
  ];

  Future<void> _openReportDialog() async {
    String selectedReason = _reasons.first;
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              setDialogState(() => isSubmitting = true);

              try {
                await _reportService.submitReport(
                  bookingId: widget.bookingId,
                  homeownerId: user.uid,
                  homeownerName: user.displayName ?? 'Homeowner',
                  providerId: widget.providerId,
                  providerName: widget.providerName,
                  reason: selectedReason,
                  description: descriptionController.text,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Report submitted. Our admin team will review it.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to submit report: $e')),
                  );
                }
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B192C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              title: Text(
                'Report ${widget.providerName}',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ...(_reasons.map((reason) => RadioListTile<String>(
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (val) =>
                              setDialogState(() => selectedReason = val!),
                          activeColor: const Color(0xFF38BDF8),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            reason,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 12),
                          ),
                        ))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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
                      : Text('Submit Report',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provider: ${widget.providerName}',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${widget.status[0].toUpperCase()}${widget.status.substring(1)}',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ProgressTimeline(
                bookingId: widget.bookingId,
                providerId: widget.providerId,
                showAddButton: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _openReportDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor:
                        Colors.redAccent.withValues(alpha: 0.05),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: Text(
                    'Report Provider',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}