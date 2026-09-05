import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/provider_bottom_nav_bar.dart';
import '../homeowner/provider_list_screen.dart';

/// Lets a logged-in provider account browse service categories and book
/// another provider, just like a homeowner can. This screen intentionally
/// does NOT look up the current user's name/role from Firestore, so it
/// never shows the wrong account's data — it just stays on whichever
/// account is currently signed in.
class ProviderBookServiceScreen extends StatefulWidget {
  const ProviderBookServiceScreen({super.key});

  @override
  State<ProviderBookServiceScreen> createState() =>
      _ProviderBookServiceScreenState();
}

class _ProviderBookServiceScreenState
    extends State<ProviderBookServiceScreen> {
  String searchQuery = '';
  String selectedFilter = 'All';

  Map<String, dynamic> _getCategoryMeta(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('repair') || lower.contains('computer')) {
      return {"icon": Icons.build_rounded, "tag": "Repair"};
    } else if (lower.contains('plumbing') ||
        lower.contains('electrical') ||
        lower.contains('aircon') ||
        lower.contains('network')) {
      return {"icon": Icons.home_repair_service_rounded, "tag": "Maintenance"};
    } else if (lower.contains('cleaning') ||
        lower.contains('upholstery') ||
        lower.contains('manicure') ||
        lower.contains('pedicure')) {
      return {"icon": Icons.cleaning_services_rounded, "tag": "Cleaning"};
    }
    return {"icon": Icons.handyman_rounded, "tag": "Maintenance"};
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Maintenance', 'Repair', 'Cleaning'];

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 1),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER (no account lookups here on purpose) ---
                    Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                          ),
                        Text(
                          'Book a Provider',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- SEARCH BAR ---
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
                          const Icon(Icons.search_rounded,
                              color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => searchQuery = val),
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 13),
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
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 18),
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 14),
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
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                  color: Color(0xFF38BDF8)),
                            ),
                          );
                        }

                        final docs =
                            snapshot.hasData ? snapshot.data!.docs : [];
                        final Map<String, Map<String, dynamic>>
                            dynamicCategories = {};

                        final defaults = [
                          {
                            "title": "Appliance Repair",
                            "desc":
                                "Refrigerator, washing machine, microwave",
                            "tag": "Repair"
                          },
                          {
                            "title": "Plumbing",
                            "desc": "Leaks, clogged drains, pipe fitting",
                            "tag": "Maintenance"
                          },
                          {
                            "title": "Electrical Work",
                            "desc": "Wiring, lighting, outlets installation",
                            "tag": "Maintenance"
                          },
                          {
                            "title": "Aircon Maintenance",
                            "desc": "Cleaning, repair, freon refill",
                            "tag": "Maintenance"
                          },
                          {
                            "title": "House Cleaning",
                            "desc": "Deep cleaning, sanitation, chores",
                            "tag": "Cleaning"
                          },
                          {
                            "title": "Computer Repair",
                            "desc": "Hardware, software, formatting",
                            "tag": "Repair"
                          },
                          {
                            "title": "Network Setup",
                            "desc": "WiFi router, fiber line, signal booster",
                            "tag": "Repair"
                          },
                          {
                            "title": "Upholstery Cleaning",
                            "desc": "Sofa, mattress, carpet cleaning",
                            "tag": "Cleaning"
                          },
                        ];

                        for (var d in defaults) {
                          dynamicCategories[d['title']!] = d;
                        }

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final serviceTitle =
                              data['service'] ?? data['serviceCategory'];
                          if (serviceTitle != null &&
                              serviceTitle.toString().trim().isNotEmpty) {
                            final meta = _getCategoryMeta(serviceTitle);
                            dynamicCategories[serviceTitle] = {
                              "title": serviceTitle,
                              "desc": data['experience'] ??
                                  'Verified professional service provider',
                              "tag": meta['tag'],
                            };
                          }
                        }

                        final categoriesList =
                            dynamicCategories.values.toList();

                        final filteredCategories =
                            categoriesList.where((cat) {
                          final title = cat['title'].toString().toLowerCase();
                          final desc = cat['desc'].toString().toLowerCase();
                          final tag = cat['tag'].toString();
                          final query = searchQuery.toLowerCase();

                          final matchesQuery =
                              title.contains(query) || desc.contains(query);
                          final matchesFilter = selectedFilter == 'All' ||
                              tag == selectedFilter;

                          return matchesQuery && matchesFilter;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
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
                                              categoryTitle:
                                                  cat['title'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
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
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                            0xFF0EA5E9)
                                                        .withValues(
                                                            alpha: 0.2),
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cat['title'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    cat['desc'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.4),
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.03),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
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
}