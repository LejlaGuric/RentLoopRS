class AdminListingReview {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String user;

  AdminListingReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.user,
  });

  factory AdminListingReview.fromJson(Map<String, dynamic> json) {
    return AdminListingReview(
      id: json['id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: (json['user'] ?? 'Nepoznat korisnik').toString(),
    );
  }
}