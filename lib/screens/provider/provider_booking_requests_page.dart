import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking_request_card.dart';


class ProviderBookingRequestsPage extends StatelessWidget {
  final String providerId;

  const ProviderBookingRequestsPage({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getPendingBookings(providerId),
        builder: (context, snapshot) {
          // Show loading indicator while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message if something goes wrong
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading bookings'),
            );
          }

          final bookings = snapshot.data ?? [];

          // Show message if no pending bookings
          if (bookings.isEmpty) {
            return const Center(
              child: Text('No pending booking requests'),
            );
          }

          // Display list of bookings
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return BookingRequestCard(
                booking: booking,
                onAccept: () async {
                  await bookingService.updateBookingStatus(
                    bookingId: booking.id,
                    newStatus: 'accepted',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking accepted'),
                      ),
                    );
                  }
                },
                onReject: () async {
                  await bookingService.updateBookingStatus(
                    bookingId: booking.id,
                    newStatus: 'rejected',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking rejected'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}