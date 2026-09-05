import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../widgets/bottom_nav_bar.dart';
import 'provider_list_screen.dart';

class HomeownerHomeScreen extends StatefulWidget {
  const HomeownerHomeScreen({super.key});

  @override
  State<HomeownerHomeScreen> createState() => _HomeownerHomeScreenState();
}

class _HomeownerHomeScreenState extends State<HomeownerHomeScreen> {
  String userName = 'User';
  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            userName = data['fullName'] ?? data['name'] ?? data['username'] ?? 'User';
          });
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  Map<String, dynamic> _getCategoryMeta(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('repair') || lower.contains('computer')) {
      return {"icon": Icons.build_rounded, "tag": "Repair"};
    } else if (lower.contains('plumbing') || lower.contains('electrical') || lower.contains('aircon') || lower.contains('network')) {
      return {"icon": Icons.home_repair_service_rounded, "tag": "Maintenance"};
    } else if (lower.contains('cleaning') || lower.contains('upholstery') || lower.contains('manicure') || lower.contains('pedicure')) {
      return {"icon": Icons.cleaning_services_rounded, "tag": "Cleaning"};
    }
    return {"icon": Icons.handyman_rounded, "tag": "Maintenance"};
  }

  // ✅ NEW: HOA Suggestions Dialog Modal
  void _showHaoSuggestionsDialog() {
    final TextEditingController suggestionController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0B192C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          title: Text(
            'HOA Suggestion Box',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send your recommendations or feedback for Golden City Dasma 1 community improvements.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: suggestionController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type your suggestion here...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.3),
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final text = suggestionController.text.trim();
                      if (text.isEmpty) return;

                      setDialogState(() => isSubmitting = true);

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await FirebaseFirestore.instance.collection('hoa_suggestions').add({
                          'userId': user?.uid ?? 'anonymous',
                          'userName': userName,
                          'suggestion': text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Suggestion sent to HOA successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
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
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Maintenance', 'Repair', 'Cleaning'];

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showHaoSuggestionsDialog,
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
        label: Text(
          'HOA Suggestion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COMPACT SLIM EXECUTIVE HEADER ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF38BDF8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'RESIDENT PORTAL',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              _buildIconButton(Icons.notifications_none_rounded, () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- SLEEK SEARCH BAR ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => searchQuery = val),
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search service, category, provider...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => searchQuery = ''),
                              child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- FILTER CHIPS ---
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filters.length,
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final isSelected = selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // --- LIVE FIRESTORE STREAM FOR APPROVED SERVICES ---
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('providers')
                          .where('verificationStatus', isEqualTo: 'approved')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                            ),
                          );
                        }

                        final docs = snapshot.hasData ? snapshot.data!.docs : [];
                        final Map<String, Map<String, dynamic>> dynamicCategories = {};

                        final defaults = [
                          {"title": "Appliance Repair", "desc": "Refrigerator, washing machine, microwave", "tag": "Repair"},
                          {"title": "Plumbing", "desc": "Leaks, clogged drains, pipe fitting", "tag": "Maintenance"},
                          {"title": "Electrical Work", "desc": "Wiring, lighting, outlets installation", "tag": "Maintenance"},
                          {"title": "Aircon Maintenance", "desc": "Cleaning, repair, freon refill", "tag": "Maintenance"},
                          {"title": "House Cleaning", "desc": "Deep cleaning, sanitation, chores", "tag": "Cleaning"},
                          {"title": "Computer Repair", "desc": "Hardware, software, formatting", "tag": "Repair"},
                          {"title": "Network Setup", "desc": "WiFi router, fiber line, signal booster", "tag": "Repair"},
                          {"title": "Upholstery Cleaning", "desc": "Sofa, mattress, carpet cleaning", "tag": "Cleaning"},
                        ];

                        for (var d in defaults) {
                          dynamicCategories[d['title']!] = d;
                        }

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final serviceTitle = data['service'] ?? data['serviceCategory'];
                          if (serviceTitle != null && serviceTitle.toString().trim().isNotEmpty) {
                            final meta = _getCategoryMeta(serviceTitle);
                            dynamicCategories[serviceTitle] = {
                              "title": serviceTitle,
                              "desc": data['experience'] ?? 'Verified professional service provider',
                              "tag": meta['tag'],
                            };
                          }
                        }

                        final categoriesList = dynamicCategories.values.toList();

                        final filteredCategories = categoriesList.where((cat) {
                          final title = cat['title'].toString().toLowerCase();
                          final desc = cat['desc'].toString().toLowerCase();
                          final tag = cat['tag'].toString();
                          final query = searchQuery.toLowerCase();

                          final matchesQuery = title.contains(query) || desc.contains(query);
                          final matchesFilter = selectedFilter == 'All' || tag == selectedFilter;

                          return matchesQuery && matchesFilter;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available Services',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '${filteredCategories.length} verified',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = filteredCategories[index];
                                final meta = _getCategoryMeta(cat['title']);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.025),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProviderListScreen(
                                              categoryTitle: cat['title'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                meta['icon'],
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
                                                    cat['title'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    cat['desc'],
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
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.03),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white.withValues(alpha: 0.4),
                                                size: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}