import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soul_matcher/app/data/models/location_suggestion.dart';

class LocationSearchService {
  Future<List<LocationSuggestion>> searchAddresses(
    String query, {
    int limit = 6,
  }) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) {
      return const <LocationSuggestion>[];
    }

    final Uri uri =
        Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
          'q': trimmedQuery,
          'format': 'jsonv2',
          'accept-language': 'en',
          'addressdetails': '1',
          'limit': '$limit',
        });

    final http.Response response = await http.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
        'Accept-Language': 'en',
        'User-Agent': 'SoulMatch/1.0 (Flutter)',
      },
    );

    if (response.statusCode != 200) {
      return const <LocationSuggestion>[];
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <LocationSuggestion>[];
    }

    final List<LocationSuggestion> suggestions = <LocationSuggestion>[];
    for (final dynamic item in decoded) {
      if (item is Map) {
        final Map<String, dynamic> map = item.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );
        final LocationSuggestion suggestion = LocationSuggestion.fromNominatim(
          map,
        );
        if (suggestion.displayName.isNotEmpty) {
          suggestions.add(suggestion);
        }
      }
    }

    return suggestions;
  }
}
