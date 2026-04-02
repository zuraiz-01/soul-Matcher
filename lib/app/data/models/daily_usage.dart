class DailyUsage {
  const DailyUsage({
    required this.dateKey,
    this.swipesCount = 0,
    this.superLikesCount = 0,
    this.messagesCount = 0,
  });

  final String dateKey;
  final int swipesCount;
  final int superLikesCount;
  final int messagesCount;

  factory DailyUsage.fromMap({
    required String dateKey,
    required Map<String, dynamic> map,
  }) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DailyUsage(
      dateKey: dateKey,
      swipesCount: parseInt(map['swipesCount']),
      superLikesCount: parseInt(map['superLikesCount']),
      messagesCount: parseInt(map['messagesCount']),
    );
  }
}
