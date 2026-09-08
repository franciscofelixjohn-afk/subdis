import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_booking_screen.dart';
import 'user_booking_status_page.dart';
import '../chat/chat_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryTitle;

  const ProviderListScreen({
    super.key,
    required this.categoryTitle,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getDisplayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['fullName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return 'Unnamed Provider';
  }

  String getServiceCategory(Map<String, dynamic> data) {
    final category = (data['service'] ??
            data['serviceCategory'] ??
            data['category'] ??
            '')
        .toString()
        .trim();
    if (category.isNotEmpty) return category;
    return 'General Service';
  }

  String getEmail(Map<String, dynamic> data) {
    final email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email;
    return 'No email available';
  }

  bool matchesCategory(String providerCategory, String selectedCategory) {
    final providerValue = providerCategory.toLowerCase().trim();
    final selectedValue = selectedCategory.toLowerCase().trim();

    if (providerValue == selectedValue) return true;

    if (selectedValue == 'plumbing' && providerValue.contains('plumb')) {
      return true;
    }

    if (selectedValue == 'electrical work' &&
        (providerValue.contains('electrical') ||
            providerValue.contains('electrician'))) {
      return true;
    }

    if (selectedValue == 'house cleaning' &&
        providerValue.contains('clean')) {
      return true;
    }

    if (selectedValue == 'aircon maintenance' &&
        providerValue.contains('aircon')) {
      return true;
    }

    if (selectedValue == 'computer / laptop repair' &&
        (providerValue.contains('computer') ||
            providerValue.contains('laptop'))) {
      return true;
    }

    if (selectedValue == 'phone / tablet repair' &&
        (providerValue.contains('phone') || providerValue.contains('tablet'))) {
      return true;
    }

    if (selectedValue == 'appliance repair' &&
        providerValue.contains('appliance')) {
      return true;
    }

    return false;
  }

  Future<void> _openCreateBookingScreen(
    BuildContext context, {
    required String providerId,
    required String providerName,
    required String providerCategory,
  }) async {
    final bookingCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingScreen(
          providerId: providerId,
          providerName: providerName,
          providerCategory: providerCategory,
        ),
      ),
    );

    if (bookingCreated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking created successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserBookingStatusPage(
            userId: currentUser.uid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providersStream = FirebaseFirestore.instance
        .collection('providers')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020408),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
      ),
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
            child: Column(
              children: [
                // Search Filter Bar (Notes: Search Filter feature)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search provider by name...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF38BDF8),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: providersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF38BDF8),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Failed to load providers: ${snapshot.error}',
                              style: GoogleFonts.poppins(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];

                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid;

                      // 1. Exclude the currently logged-in provider's own
                      //    account (a provider should never see/book themself)
                      // 2. Filter by Category
                      // 3. Filter by Search Query
                      // 4. AI / System Recommendation Sorting (e.g., Verified or top rated first)
                      final filteredDocs = allDocs.where((doc) {
                        if (currentUid != null && doc.id == currentUid) {
                          return false;
                        }

                        final data = doc.data();
                        final serviceCategory = getServiceCategory(data);
                        final name = getDisplayName(data).toLowerCase();

                        final matchesCat = matchesCategory(
                            serviceCategory, widget.categoryTitle);
                        final matchesSearch = name.contains(_searchQuery);

                        return matchesCat && matchesSearch;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
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
                                    Icons.engineering_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Providers Found',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No matching service providers available under "${widget.categoryTitle}".',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data();

                          final providerId = doc.id;
                          final providerName = getDisplayName(data);
                          final providerCategory = getServiceCategory(data);
                          final email = getEmail(data);
                          final status = (data['verificationStatus'] ?? 'pending')
                              .toString()
                              .toLowerCase();
                          final accountStatus =
                              (data['status'] ?? 'Active').toString();
                          final isRestrictedOrSuspended =
                              accountStatus == 'Restricted' ||
                                  accountStatus == 'Suspended';

                          // System Recommendation Badge logic
                          final isRecommended = status == 'approved';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isRecommended
                                    ? const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.06),
                                width: isRecommended ? 1.2 : 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  await _openCreateBookingScreen(
                                    context,
                                    providerId: providerId,
                                    providerName: providerName,
                                    providerCategory: providerCategory,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
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
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0EA5E9)
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.handyman_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    providerName,
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                ),
                                                if (isRestrictedOrSuspended) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: (accountStatus ==
                                                                  'Suspended'
                                                              ? Colors.redAccent
                                                              : Colors
                                                                  .orangeAccent)
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                      border: Border.all(
                                                        color: (accountStatus ==
                                                                    'Suspended'
                                                                ? Colors
                                                                    .redAccent
                                                                : Colors
                                                                    .orangeAccent)
                                                            .withValues(
                                                                alpha: 0.4),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      accountStatus,
                                                      style: GoogleFonts.poppins(
                                                        color: accountStatus ==
                                                                'Suspended'
                                                            ? Colors.redAccent
                                                            : Colors
                                                                .orangeAccent,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (isRecommended) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFF10B981)
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                      border: Border.all(
                                                        color: const Color(
                                                                0xFF10B981)
                                                            .withValues(
                                                                alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Recommended',
                                                      style: GoogleFonts.poppins(
                                                        color: const Color(
                                                            0xFF10B981),
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0284C7)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                          0xFF38BDF8)
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                providerCategory,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(
                                                      0xFF38BDF8),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              email,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tap to continue booking',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF38BDF8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: const Color(0xFF0284C7)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatScreen(
                                                      otherUserId: providerId,
                                                      otherUserName:
                                                          providerName,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                  border: Border.all(
                                                    color: const Color(
                                                            0xFF38BDF8)
                                                        .withValues(
                                                            alpha: 0.3),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.chat_bubble_rounded,
                                                  color: Color(0xFF38BDF8),
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white
                                                .withValues(alpha: 0.3),
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }
}