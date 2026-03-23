class LocationSuggestion {
  const LocationSuggestion({
    required this.displayName,
    required this.primaryText,
    required this.secondaryText,
  });

  final String displayName;
  final String primaryText;
  final String secondaryText;

  factory LocationSuggestion.fromNominatim(Map<String, dynamic> data) {
    final String displayName = (data['display_name'] as String? ?? '').trim();
    final List<String> segments = displayName
        .split(',')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    final String primaryText = segments.isNotEmpty
        ? segments.first
        : displayName;
    final String secondaryText = segments.length > 1
        ? segments.sublist(1).join(', ')
        : '';

    return LocationSuggestion(
      displayName: displayName,
      primaryText: primaryText,
      secondaryText: secondaryText,
    );
  }
}
