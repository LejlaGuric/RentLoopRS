class ReviewCreateRequest {
  final int reservationId;
  final int rating; // 1..5
  final String comment;

  ReviewCreateRequest({
    required this.reservationId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'rating': rating,
        'comment': comment,
      };
}
