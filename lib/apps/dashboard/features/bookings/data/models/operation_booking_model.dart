import '../../domain/entities/operation_booking.dart';

class OperationBookingModel extends OperationBooking {
  const OperationBookingModel({
    required super.id,
    required super.passengerName,
    required super.phone,
    required super.route,
    required super.tripTime,
    required super.date,
    required super.seat,
    required super.paymentMethod,
    required super.status,
    required super.assignedTrip,
    required super.customerProfile,
    required super.tripDetails,
    required super.paymentDetails,
    required super.attachments,
    required super.notes,
    required super.history,
  });

  factory OperationBookingModel.fromEntity(OperationBooking booking) {
    return OperationBookingModel(
      id: booking.id,
      passengerName: booking.passengerName,
      phone: booking.phone,
      route: booking.route,
      tripTime: booking.tripTime,
      date: booking.date,
      seat: booking.seat,
      paymentMethod: booking.paymentMethod,
      status: booking.status,
      assignedTrip: booking.assignedTrip,
      customerProfile: booking.customerProfile,
      tripDetails: booking.tripDetails,
      paymentDetails: booking.paymentDetails,
      attachments: booking.attachments,
      notes: booking.notes,
      history: booking.history,
    );
  }
}
