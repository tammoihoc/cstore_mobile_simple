import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Reverse-geocodes (lat, lng) → human-readable Vietnamese address
/// using the Nominatim API (free, matches the OSM tiles we already use).
class GeocodingService {
  GeocodingService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Timer? _debounce;
  Completer<String?>? _pending;

  static const _baseUrl = String.fromEnvironment(
    'GEOCODING_URL',
    defaultValue: 'https://nominatim.openstreetmap.org/reverse',
  );
  static const _userAgent = 'CStoreMobile/1.0';
  static final _cache = <String, String>{};
  static Future<void> _queue = Future.value();
  static DateTime? _lastRequest;

  /// Returns a formatted address for the given coordinates, or `null` on
  /// failure.  Calls are debounced: if a new request arrives within 400 ms
  /// of the previous one, the earlier request is cancelled (returns `null`).
  Future<String?> reverse(
    double lat,
    double lng,
  ) {
    // Cancel any pending debounce.
    _debounce?.cancel();
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete(null);
    }
    final completer = Completer<String?>();
    _pending = completer;

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _fetch(
          lat,
          lng,
        ).then(
          (addr) {
            if (!completer.isCompleted) completer.complete(addr);
          },
        ).catchError(
          (_) {
            if (!completer.isCompleted) completer.complete(null);
          },
        );
      },
    );

    return completer.future;
  }

  Future<String?> _fetch(
    double lat,
    double lng,
  ) async {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (_cache.containsKey(key)) return _cache[key];
    final result = Completer<String?>();
    _queue = _queue.then(
      (_) async {
        try {
          final elapsed = _lastRequest == null
              ? 1100
              : DateTime.now().difference(_lastRequest!).inMilliseconds;
          if (elapsed < 1100) {
            await Future<void>.delayed(Duration(milliseconds: 1100 - elapsed));
          }
          _lastRequest = DateTime.now();
          final address = await _request(
            lat,
            lng,
          );
          if (address != null) {
            if (_cache.length >= 100) _cache.remove(_cache.keys.first);
            _cache[key] = address;
          }
          result.complete(address);
        } catch (_) {
          result.complete(null);
        }
      },
    );
    return result.future;
  }

  Future<String?> _request(
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'accept-language': 'vi',
        'zoom': '18',
        'addressdetails': '1',
        'layer': 'address',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return _format(json);
  }

  /// Build a concise address from the structured `address` object, falling
  /// back to `display_name` when structured parts are absent.
  String? _format(
    Map<String, dynamic> json,
  ) {
    final addr = json['address'] as Map<String, dynamic>?;
    if (addr == null) return json['display_name'] as String?;

    final parts = <String>[];

    // House number + road
    final house = addr['house_number'] as String?;
    final road = (addr['road'] ??
        addr['pedestrian'] ??
        addr['residential'] ??
        addr['footway'] ??
        addr['path']) as String?;
    if (road != null) {
      parts.add(house != null ? '$house $road' : road);
    }

    // Suburb / quarter
    final suburb =
        addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood'] as String?;
    if (suburb != null) parts.add(suburb as String);

    // District / city_district
    final district = addr['city_district'] ?? addr['county'] as String?;
    if (district != null) parts.add(district as String);

    // City / town / village
    final city = addr['city'] ?? addr['town'] ?? addr['village'] as String?;
    if (city != null) parts.add(city as String);

    // Province / state
    final state = addr['state'] as String?;
    if (state != null) parts.add(state);

    if (parts.isEmpty) {
      return json['display_name'] as String?;
    }
    return parts.toSet().join(', ');
  }

  void dispose() {
    _debounce?.cancel();
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete(null);
    }
    if (_ownsClient) _client.close();
  }
}
