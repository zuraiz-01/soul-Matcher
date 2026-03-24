class UserActivityItem {
  const UserActivityItem({
    required this.targetUserId,
    this.createdAt,
    this.reason,
  });

  final String targetUserId;
  final DateTime? createdAt;
  final String? reason;
}
