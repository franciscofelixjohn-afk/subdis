import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/bottom_nav_bar.dart';
import '../chat/chat_screen.dart';
import 'booking_progress_screen.dart';

class ActiveBookingsScreen extends StatelessWidget {
  const ActiveBookingsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'accepted':
        return const Color(0xFF10B981); // Emerald Green
      case 'rejected':
        return const Color(0xFFEF4444); // Soft Red
      case 'completed':
        return const Color(0xFF38BDF8); // Electric Cyan
      default:
        return Colors.white70;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'rejected':
        return 'REJECTED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF020408),
        body: Center(
          child: Text(
            'No logged-in user found.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 1,
      ),
      body: Stack(
        children: [
          // 1. Deep Obsidian Luxury Gradient Background
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
          // 2. Soft Ambient Cyan Glow
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Text(
                    'My Bookings',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your active appointments and service history',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BOOKINGS STREAM ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('homeownerId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF38BDF8),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.poppins(color: Colors.redAccent),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Color(0xFF38BDF8),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings found.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your requested services will appear here.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bookings = docs.toList()
                          ..sort((a, b) {
                            final aData = a.data();
                            final bData = b.data();

                            final aTimestamp = aData['selectedDate'];
                            final bTimestamp = bData['selectedDate'];

                            DateTime aDate =
                                DateTime.fromMillisecondsSinceEpoch(0);
                            DateTime bDate =
                                DateTime.fromMillisecondsSinceEpoch(0);

                            if (aTimestamp is Timestamp) {
                              aDate = aTimestamp.toDate();
                            }

                            if (bTimestamp is Timestamp) {
                              bDate = bTimestamp.toDate();
                            }

                            return bDate.compareTo(aDate);
                          });

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: bookings.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bookingDoc = bookings[index];
                            final booking = bookingDoc.data();
                            final String bookingId = bookingDoc.id;

                            final String providerId =
                                (booking['providerId'] ?? '').toString();

                            final String providerName =
                                (booking['providerName'] ?? 'Unknown Provider')
                                    .toString();

                            final String service =
                                (booking['service'] ?? 'Unknown Service')
                                    .toString();

                            final String date =
                                (booking['bookingDate'] ?? 'No Date')
                                    .toString();

                            final String time =
                                (booking['bookingTime'] ?? 'No Time')
                                    .toString();

                            final String status =
                                (booking['status'] ?? 'pending').toString();

                            final Color statusColor = _getStatusColor(status);

                            // --- HIGH-END GLASS CARD DESIGN ---
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0EA5E9),
                                              Color(0xFF1D4ED8)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0EA5E9)
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.handyman_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              providerName,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              service,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: statusColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusLabel(status),
                                          style: GoogleFonts.poppins(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        date,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        time,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 38,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BookingProgressScreen(
                                                    bookingId: bookingId,
                                                    providerId: providerId,
                                                    providerName:
                                                        providerName,
                                                    service: service,
                                                    status: status,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.15),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.02),
                                            ),
                                            child: Text(
                                              'View Details',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 38,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ChatScreen(
                                                    otherUserId: providerId,
                                                    otherUserName:
                                                        providerName,
                                                    bookingId: bookingId,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0284C7),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Message',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}