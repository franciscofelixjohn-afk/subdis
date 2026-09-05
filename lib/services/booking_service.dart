import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('bookings');

  // ✅ NEW: CREATE BOOKING
  Future<String> createBooking({
    required String homeownerId,
    required String homeownerName,
    required String homeownerEmail,
    required String providerId,
    required String providerName,
    required String providerCategory,
    required String service,
    required String address,
    required String notes,
    required DateTime bookingDateTime,
    required String bookingDate,
    required String bookingTime,
  }) async {
    final bookingRef = _bookingsRef.doc();

    await bookingRef.set({
      'bookingId': bookingRef.id,
      'homeownerId': homeownerId,
      'homeownerName': homeownerName,
      'homeownerEmail': homeownerEmail,
      'providerId': providerId,
      'providerName': providerName,
      'providerCategory': providerCategory,
      'service': service,
      'address': address,
      'notes': notes,
      'selectedDate': Timestamp.fromDate(bookingDateTime),
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return bookingRef.id;
  }

  Stream<List<BookingModel>> getPendingBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getAcceptedBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getCompletedBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _bookingsRef
        .where('homeownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();

      list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      return list;
    });
  }

  Future<int> getAcceptedJobsCount(String providerId) async {
    final snapshot = await _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return snapshot.docs.length;
  }

  Future<double> getWeeklyEarnings(String providerId) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final snapshot = await _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      DateTime? bookingDate;
      final rawSelectedDate = data['selectedDate'];

      if (rawSelectedDate is Timestamp) {
        bookingDate = rawSelectedDate.toDate();
      } else if (rawSelectedDate is DateTime) {
        bookingDate = rawSelectedDate;
      }

      if (bookingDate == null) continue;

      final bookingDay = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );

      if (bookingDay.isBefore(startOfWeek)) continue;

      final rawPrice =
          data['price'] ?? data['servicePrice'] ?? data['amount'] ?? 0;

      if (rawPrice is int) {
        total += rawPrice.toDouble();
      } else if (rawPrice is double) {
        total += rawPrice;
      } else if (rawPrice is String) {
        total += double.tryParse(rawPrice) ?? 0;
      }
    }

    return total;
  }

  Stream<Map<String, dynamic>> getProviderDashboardStats(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      int acceptedJobs = 0;
      double weeklyEarnings = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();

        if (status == 'accepted') {
          acceptedJobs++;
        }

        if (status == 'completed') {
          DateTime? bookingDate;
          final rawSelectedDate = data['selectedDate'];

          if (rawSelectedDate is Timestamp) {
            bookingDate = rawSelectedDate.toDate();
          } else if (rawSelectedDate is DateTime) {
            bookingDate = rawSelectedDate;
          }

          if (bookingDate != null) {
            final bookingDay = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
            );

            if (!bookingDay.isBefore(startOfWeek)) {
              final rawPrice =
                  data['price'] ?? data['servicePrice'] ?? data['amount'] ?? 0;

              if (rawPrice is int) {
                weeklyEarnings += rawPrice.toDouble();
              } else if (rawPrice is double) {
                weeklyEarnings += rawPrice;
              } else if (rawPrice is String) {
                weeklyEarnings += double.tryParse(rawPrice) ?? 0;
              }
            }
          }
        }
      }

      return {
        'acceptedJobs': acceptedJobs,
        'weeklyEarnings': weeklyEarnings,
      };
    });
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    final normalizedNewStatus = newStatus.trim().toLowerCase();

    await _firestore.runTransaction((transaction) async {
      final docRef = _bookingsRef.doc(bookingId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Booking not found.');
      }

      final data = snapshot.data();
      if (data == null) {
        throw Exception('Booking data is empty.');
      }

      final currentStatus = (data['status'] ?? '').toString().toLowerCase();

      if (!_isValidStatus(normalizedNewStatus)) {
        throw Exception('Invalid target booking status: $normalizedNewStatus');
      }

      if (!_canTransition(currentStatus, normalizedNewStatus)) {
        throw Exception(
          'Invalid booking status transition: $currentStatus -> $normalizedNewStatus',
        );
      }

      transaction.update(docRef, {
        'status': normalizedNewStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ✅ NEW: ISOLATED RATING & REVIEW REFLECTION
  Future<void> submitBookingRating({
    required String bookingId,
    required String providerId,
    required String providerCategory,
    required double rating,
    required String comment,
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingRef);

      if (!snapshot.exists) {
        throw Exception('Booking not found.');
      }

      transaction.update(bookingRef, {
        'rating': rating,
        'comment': comment,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    });

    final providerCategoryRatingRef = _firestore
        .collection('providers')
        .doc(providerId)
        .collection('category_ratings')
        .doc(providerCategory.toLowerCase());

    final catDoc = await providerCategoryRatingRef.get();
    
    if (catDoc.exists) {
      final data = catDoc.data()!;
      final double currentTotalRating = (data['totalRating'] ?? 0.0).toDouble();
      final int currentCount = (data['ratingCount'] ?? 0).toInt();

      final newCount = currentCount + 1;
      final newAverage = (currentTotalRating + rating) / newCount;

      await providerCategoryRatingRef.set({
        'category': providerCategory,
        'totalRating': currentTotalRating + rating,
        'ratingCount': newCount,
        'averageRating': newAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await providerCategoryRatingRef.set({
        'category': providerCategory,
        'totalRating': rating,
        'ratingCount': 1,
        'averageRating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  bool _isValidStatus(String status) {
    return status == 'pending' ||
        status == 'accepted' ||
        status == 'rejected' ||
        status == 'completed';
  }

  bool _canTransition(String currentStatus, String newStatus) {
    if (currentStatus == newStatus) return false;

    switch (currentStatus) {
      case 'pending':
        return newStatus == 'accepted' || newStatus == 'rejected';
      case 'accepted':
        return newStatus == 'completed';
      case 'rejected':
        return false;
      case 'completed':
        return false;
      default:
        return false;
    }
  }
}