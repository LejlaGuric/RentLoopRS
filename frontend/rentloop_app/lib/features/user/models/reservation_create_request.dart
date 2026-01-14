class ReservationCreateRequest {
  final int listingId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String? note;

  ReservationCreateRequest({
    required this.listingId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'checkIn': checkIn.toUtc().toIso8601String(),
        'checkOut': checkOut.toUtc().toIso8601String(),
        'guests': guests,
        'note': note,
      };
}
