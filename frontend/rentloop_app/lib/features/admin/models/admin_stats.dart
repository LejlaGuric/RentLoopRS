class AdminStats {
  final int usersCount;
  final int activeUsersCount;
  final int listingsCount;
  final int reservationsCount;
  final int pendingReservations;
  final double avgRating;

  const AdminStats({
    required this.usersCount,
    required this.activeUsersCount,
    required this.listingsCount,
    required this.reservationsCount,
    required this.pendingReservations,
    required this.avgRating,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      usersCount: (json['usersCount'] as num).toInt(),
      activeUsersCount: (json['activeUsersCount'] as num).toInt(),
      listingsCount: (json['listingsCount'] as num).toInt(),
      reservationsCount: (json['reservationsCount'] as num).toInt(),
      pendingReservations: (json['pendingReservations'] as num).toInt(),
      avgRating: (json['avgRating'] as num).toDouble(),
    );
  }
}
