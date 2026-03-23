enum SwipeType { pass, like, superLike }

class SwipeActionModel {
  const SwipeActionModel({
    required this.byUserId,
    required this.targetUserId,
    required this.type,
    this.createdAt,
  });

  final String byUserId;
  final String targetUserId;
  final SwipeType type;
  final DateTime? createdAt;

  String get firestoreValue {
    switch (type) {
      case SwipeType.pass:
        return 'pass';
      case SwipeType.like:
        return 'like';
      case SwipeType.superLike:
        return 'super_like';
    }
  }
}
