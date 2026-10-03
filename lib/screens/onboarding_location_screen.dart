import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

/// Shown once right after registration/first login, before the user reaches
/// the main app, when the profile has no saved location yet (see the
/// router's redirect) — mandatory, no skip. Also collects the display name
/// here — phone/OTP signups can go through without ever typing one
/// (AuthController falls back to "User 1234"), so this is the first
/// guaranteed checkpoint for every signup path, not just a location step.
///
/// Location capture is either automatic (GPS + Google Geocoding reverse
/// lookup) or via Places Autocomplete search. Autocomplete/Details use the
/// New Places API (places.googleapis.com/v1) — the legacy endpoints
/// (maps.googleapis.com/maps/api/place/*) are REQUEST_DENIED on this
/// project's API key. Reverse geocoding still goes through the classic
/// Geocoding API, a separate product from Places that must be enabled (and
/// added to the key's API restrictions) on the same Google Cloud project.
///
/// Once a location resolves, its address_components are broken out into the
/// same city/area/district/state/country/pincode fields the rest of the app
/// already uses (profile_screen.dart edits city/district directly) — shown
/// editable since Google's data can be imprecise for rural/village addresses.
class OnboardingLocationScreen extends StatefulWidget {
  const OnboardingLocationScreen({super.key});

  @override
  State<OnboardingLocationScreen> createState() =>
      _OnboardingLocationScreenState();
}

class _OnboardingLocationScreenState extends State<OnboardingLocationScreen> {
  static const _primary = Color(0xFFE65100);
  static const _placesBase = 'https://places.googleapis.com/v1';
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final _searchCtrl = TextEditingController();
  late final TextEditingController _nameCtrl;
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>();
  final _searchFocus = FocusNode();
  int _step = 0;
  int _searchVersion = 0;
  bool _searching = false;
  bool _searched = false;
  bool _locating = false;
  bool _saving = false;
  String? _error;
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;

  // Selected result, either from GPS or from a tapped suggestion.
  String? _resolvedAddress;
  double? _lat;
  double? _lng;
  String? _placeId;

  // Manual entry: shown after GPS fails, or on request. Coordinates come from
  // [_gpsFix] if GPS worked but reverse geocoding didn't, else from
  // forward-geocoding the typed fields at save time.
  bool _manual = false;
  String? _manualNotice;
  Position? _gpsFix;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: context.read<AuthProvider>().user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _dio.close(force: true);
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  /// Normalizes address components from either Google API into
  /// {type -> longest matching text} and fills the breakdown controllers.
  /// Assam addresses commonly carry both administrative_area_level_2 (a
  /// "Division", e.g. "Lower Assam Division") and _level_3 (the actual
  /// district, e.g. "Kamrup Metropolitan") — level_3 wins when present since
  /// that matches what the rest of the app means by "district" (see
  /// coverage_districts_screen.dart's "e.g. Kamrup").
  void _applyAddressComponents(
    List<dynamic> components, {
    required bool isNewPlacesFormat,
  }) {
    String? pick(List<String> types) {
      for (final type in types) {
        for (final c in components) {
          final componentTypes = (c['types'] as List).cast<String>();
          if (componentTypes.contains(type)) {
            return isNewPlacesFormat
                ? c['longText'] as String?
                : c['long_name'] as String?;
          }
        }
      }
      return null;
    }

    final city = pick(['locality']);
    final area = pick(['sublocality_level_1', 'sublocality', 'neighborhood']);
    _cityCtrl.text = city ?? area ?? '';
    _areaCtrl.text = (area != null && area != _cityCtrl.text) ? area : '';
    _districtCtrl.text =
        pick(['administrative_area_level_3', 'administrative_area_level_2']) ??
        '';
    _stateCtrl.text = pick(['administrative_area_level_1']) ?? '';
    _countryCtrl.text = pick(['country']) ?? 'India';
    _pincodeCtrl.text = pick(['postal_code']) ?? '';
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _searchVersion++;
    setState(() {
      _locating = true;
      _error = null;
      _searching = false;
      _searched = false;
      _suggestions = [];
      _gpsFix = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _gpsFailed('Location permission denied.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _gpsFailed('Device location is turned off.');
        return;
      }

      final position = await _getPosition();
      if (!mounted) return;
      // Keep the raw fix: if the address lookup below fails, manual entry
      // can still save these coordinates instead of geocoding the typed text.
      _gpsFix = position;
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${position.latitude},${position.longitude}',
          'key': AppConstants.googlePlacesApiKey,
        },
      );

      final status = res.data['status'] as String?;
      if (status != 'OK') {
        // Coordinates were found fine (GPS worked) but Google's reverse
        // geocoding didn't (e.g. REQUEST_DENIED when billing lapses on the
        // Cloud project) — try OpenStreetMap before giving up. Never present
        // raw lat/lng as if it were an address; if both fail, tell the user
        // plainly and ask them to type it in instead.
        final osm = await _nominatimReverse(position);
        if (!mounted) return;
        if (osm == null) {
          _gpsFailed("Found your position but couldn't look up the address.");
          return;
        }
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _resolvedAddress = osm.formatted;
          _placeId = null;
          _applyNominatimAddress(osm.address);
          _locating = false;
          _suggestions = [];
          _searchCtrl.text = osm.formatted;
          _manual = false;
          _manualNotice = null;
        });
        return;
      }

      final result = (res.data['results'] as List).first;
      final formatted = result['formatted_address'] as String?;

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _resolvedAddress = formatted;
        _placeId = result['place_id'] as String?;
        _applyAddressComponents(
          result['address_components'] as List,
          isNewPlacesFormat: false,
        );
        _locating = false;
        _suggestions = [];
        _searchCtrl.text = formatted ?? '';
        _manual = false;
        _manualNotice = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      _gpsFailed("Couldn't get a GPS fix.");
    } catch (e) {
      if (!mounted) return;
      if (_isOffline(e)) {
        // GPS may have worked, but nothing can be saved offline anyway —
        // manual entry wouldn't help, so just say what's wrong.
        setState(() {
          _locating = false;
          _error = _offlineMessage;
        });
        return;
      }
      _gpsFailed("Couldn't detect your location.");
    }
  }

  /// Any GPS failure drops straight into manual entry — some devices (notably
  /// OPPO/ColorOS) never produce a fix no matter what we try, and search alone
  /// isn't enough for villages Google doesn't know by name.
  void _gpsFailed(String reason) {
    setState(() {
      _locating = false;
      _error = null;
      _manualNotice = '$reason Please enter your address manually below.';
      _enterManualMode();
    });
  }

  /// Called inside setState.
  void _enterManualMode() {
    _manual = true;
    _suggestions = [];
    _searched = false;
    _resolvedAddress = null;
    _lat = null;
    _lng = null;
    _placeId = null;
    _searchCtrl.clear();
    if (_stateCtrl.text.trim().isEmpty) _stateCtrl.text = 'Assam';
    if (_countryCtrl.text.trim().isEmpty) _countryCtrl.text = 'India';
  }

  bool get _manualComplete =>
      _cityCtrl.text.trim().isNotEmpty &&
      _districtCtrl.text.trim().isNotEmpty &&
      RegExp(r'^\d{6}$').hasMatch(_pincodeCtrl.text.trim());

  /// Forward-geocodes the typed address, falling back to the PIN code alone
  /// (always resolvable in India even when a village name isn't). Returns
  /// null if Google can't place either; rethrows when the device is offline
  /// so the caller can say so instead of silently saving without coordinates.
  Future<({double lat, double lng})?> _geocodeManualAddress(
    String address,
  ) async {
    for (final query in [address, '${_pincodeCtrl.text.trim()}, India']) {
      try {
        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          queryParameters: {
            'address': query,
            'components': 'country:IN',
            'key': AppConstants.googlePlacesApiKey,
          },
        );
        if (res.data['status'] != 'OK') continue;
        final loc = (res.data['results'] as List).first['geometry']['location'];
        return (
          lat: (loc['lat'] as num).toDouble(),
          lng: (loc['lng'] as num).toDouble(),
        );
      } catch (e) {
        if (_isOffline(e)) rethrow;
        // Otherwise try the next, coarser query.
      }
    }
    // Google couldn't place it (or is refusing requests) — same two queries
    // against OpenStreetMap.
    for (final query in [address, '${_pincodeCtrl.text.trim()}, India']) {
      try {
        final res = await _dio.get(
          '$_nominatimBase/search',
          queryParameters: {
            'q': query,
            'countrycodes': 'in',
            'format': 'jsonv2',
            'limit': 1,
          },
          options: Options(headers: _nominatimHeaders),
        );
        final results = res.data as List;
        if (results.isEmpty) continue;
        return (
          lat: double.parse(results.first['lat'] as String),
          lng: double.parse(results.first['lon'] as String),
        );
      } catch (e) {
        if (_isOffline(e)) rethrow;
      }
    }
    return null;
  }

  /// OpenStreetMap fallback for when Google Geocoding is unavailable. Free,
  /// no key; the usage policy asks for an identifying User-Agent and at most
  /// ~1 request/second, which a once-per-signup lookup is well within.
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _nominatimHeaders = {
    'User-Agent': 'NEE-App/1.0 (in.complit.neep)',
    'Accept-Language': 'en',
  };

  Future<({String formatted, Map<String, dynamic> address})?> _nominatimReverse(
    Position position,
  ) async {
    try {
      final res = await _dio.get(
        '$_nominatimBase/reverse',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
          'zoom': 18,
        },
        options: Options(headers: _nominatimHeaders),
      );
      final formatted = res.data['display_name'] as String?;
      final address = res.data['address'];
      if (formatted == null || address is! Map) return null;
      return (formatted: formatted, address: address.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Nominatim's equivalent of [_applyAddressComponents]. For Assam,
  /// state_district carries the actual district (e.g. "Kamrup Metropolitan")
  /// and county the revenue circle, so state_district wins. Called inside
  /// setState.
  void _applyNominatimAddress(Map<String, dynamic> a) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    final city = pick(['city', 'town', 'village', 'municipality']);
    final area = pick(['suburb', 'neighbourhood', 'quarter', 'hamlet']);
    _cityCtrl.text = city ?? area ?? '';
    _areaCtrl.text = (area != null && area != _cityCtrl.text) ? area : '';
    _districtCtrl.text = pick(['state_district', 'county']) ?? '';
    _stateCtrl.text = pick(['state']) ?? '';
    _countryCtrl.text = pick(['country']) ?? 'India';
    _pincodeCtrl.text = pick(['postcode']) ?? '';
  }

  /// No network route at all (airplane mode, no data, DNS failure) as
  /// opposed to Google answering with an error.
  static bool _isOffline(Object e) =>
      e is DioException &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout);

  static const _offlineMessage =
      'No internet connection. Please connect to the internet and try again.';

  /// Only needs to be good enough to reverse-geocode an address, so this
  /// favours "some fix, fast" over precision:
  ///  1. A recent cached fix is returned instantly.
  ///  2. Medium accuracy (Wi-Fi/cell assisted) instead of the default high,
  ///     which waits for a true GPS lock and routinely times out indoors.
  ///  3. On Android, if the fused provider (Play Services) never answers —
  ///     common on OPPO/Realme ColorOS builds — retry once through the
  ///     platform LocationManager, which bypasses Play Services entirely.
  Future<Position> _getPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <
              const Duration(minutes: 10)) {
        return last;
      }
    } catch (_) {
      // Not supported on every platform (e.g. web) — fall through.
    }

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 25),
        ),
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    setState(() {
      _suggestions = [];
      _resolvedAddress = null;
      _lat = null;
      _lng = null;
      _placeId = null;
      _error = null;
      _searched = false;
      _searching = value.trim().length >= 3;
    });
    if (!_searching) return;
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchSuggestions(value.trim(), version),
    );
  }

  Future<void> _fetchSuggestions(String input, int version) async {
    try {
      final res = await _dio.post(
        '$_placesBase/places:autocomplete',
        data: {
          'input': input,
          'includedRegionCodes': ['in'],
        },
        options: Options(
          contentType: 'application/json',
          headers: {'X-Goog-Api-Key': AppConstants.googlePlacesApiKey},
        ),
      );
      if (!mounted || version != _searchVersion) return;
      final suggestions = (res.data['suggestions'] as List?) ?? [];
      setState(() {
        _searching = false;
        _searched = true;
        _suggestions =
            suggestions
                .map((s) => s['placePrediction'])
                .where((p) => p != null)
                .map(
                  (p) => _PlaceSuggestion(
                    placeId: p['placeId'] as String,
                    description: p['text']?['text'] as String? ?? '',
                  ),
                )
                .toList();
      });
    } catch (e) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _searching = false;
        _error =
            _isOffline(e)
                ? _offlineMessage
                : "Search couldn't connect. Try again or enter your address manually.";
      });
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _searchVersion++;
    setState(() {
      _locating = true;
      _searching = false;
      _searched = false;
      _error = null;
      _suggestions = [];
      _searchCtrl.text = suggestion.description;
    });
    try {
      final res = await _dio.get(
        '$_placesBase/places/${suggestion.placeId}',
        options: Options(
          headers: {
            'X-Goog-Api-Key': AppConstants.googlePlacesApiKey,
            'X-Goog-FieldMask': 'location,formattedAddress,addressComponents',
          },
        ),
      );
      final location = res.data['location'];
      if (!mounted) return;
      setState(() {
        _lat = (location?['latitude'] as num?)?.toDouble();
        _lng = (location?['longitude'] as num?)?.toDouble();
        _resolvedAddress =
            res.data['formattedAddress'] as String? ?? suggestion.description;
        _placeId = suggestion.placeId;
        final components = res.data['addressComponents'] as List?;
        if (components != null) {
          _applyAddressComponents(components, isNewPlacesFormat: true);
        }
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            _isOffline(e)
                ? _offlineMessage
                : "Couldn't resolve that address. Please try again.";
        _locating = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _locating || _searching) return;
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (_manual) {
      if (!_manualComplete) return;
      setState(() {
        _saving = true;
        _error = null;
      });
      final address = [
        _areaCtrl.text,
        _cityCtrl.text,
        _districtCtrl.text,
        _stateCtrl.text,
        _pincodeCtrl.text,
        _countryCtrl.text,
      ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
      ({double lat, double lng})? coords;
      if (_gpsFix != null) {
        coords = (lat: _gpsFix!.latitude, lng: _gpsFix!.longitude);
      } else {
        try {
          coords = await _geocodeManualAddress(address);
        } catch (_) {
          // Only offline errors escape _geocodeManualAddress — and the
          // profile save below needs the network too, so stop here.
          if (!mounted) return;
          setState(() {
            _saving = false;
            _error = _offlineMessage;
          });
          return;
        }
      }
      if (!mounted) return;
      // No GPS fix and Google couldn't place the address: save the typed
      // address on its own (see ProfileModel.hasLocation).
      _resolvedAddress = address;
      _lat = coords?.lat;
      _lng = coords?.lng;
      _placeId = null;
    } else if (_resolvedAddress == null || _lat == null || _lng == null) {
      return;
    }
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().updateProfile({
      'name': name,
      'work_address': _resolvedAddress,
      'latitude': _lat,
      'longitude': _lng,
      'google_place_id': _placeId,
      'city': _cityCtrl.text.trim(),
      'area': _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'state':
          _stateCtrl.text.trim().isEmpty ? 'Assam' : _stateCtrl.text.trim(),
      'country':
          _countryCtrl.text.trim().isEmpty ? 'India' : _countryCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your details. Try again.'),
        ),
      );
    }
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _primary),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF667085), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBF360C), width: 2.5),
      ),
    );
  }

  Widget _breakdownField(TextEditingController ctrl, String label) {
    final isPincode = ctrl == _pincodeCtrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        enabled: !_saving,
        keyboardType:
            isPincode ? TextInputType.number : TextInputType.streetAddress,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        maxLength: isPincode ? 6 : null,
        onChanged: (_) {
          // Manual mode gates "Finish setup" on these fields.
          if (_manual) setState(() {});
        },
        decoration: _decoration(label).copyWith(counterText: ''),
      ),
    );
  }

  List<Widget> _buildManualEntry() {
    return [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCCAB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_location_alt_outlined, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _manualNotice ?? 'Enter your work address below.',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _breakdownField(_cityCtrl, 'City / Village *'),
      _breakdownField(_areaCtrl, 'Area / Landmark (optional)'),
      _breakdownField(_districtCtrl, 'District *'),
      _breakdownField(_pincodeCtrl, 'PIN code *'),
      _breakdownField(_stateCtrl, 'State'),
      _breakdownField(_countryCtrl, 'Country'),
      if (_error != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      TextButton.icon(
        onPressed:
            _saving
                ? null
                : () => setState(() {
                  _manual = false;
                  _manualNotice = null;
                  _error = null;
                }),
        icon: const Icon(Icons.search_rounded),
        label: const Text('Search for an address instead'),
        style: TextButton.styleFrom(foregroundColor: _primary),
      ),
    ];
  }

  void _continue() {
    if (_step == 0) {
      if (!_nameFormKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      setState(() => _step = 1);
    } else {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        _resolvedAddress != null && _lat != null && _lng != null;
    final busy = _locating || _saving || _searching;
    final canContinue =
        _step == 0 || (!busy && (_manual ? _manualComplete : hasLocation));

    return PopScope(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step == 1 && !_saving) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
                    child: Row(
                      children: [
                        if (_step == 1)
                          IconButton(
                            tooltip: 'Back to your name',
                            onPressed:
                                _saving
                                    ? null
                                    : () => setState(() => _step = 0),
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: _primary,
                            ),
                          ),
                        const Expanded(
                          child: Text(
                            'Set up your profile',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'Step ${_step + 1} of 2',
                          style: const TextStyle(
                            color: Color(0xFF657080),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        2,
                        (index) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                            decoration: BoxDecoration(
                              color:
                                  index <= _step
                                      ? _primary
                                      : const Color(0xFFE2E5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDE2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _step == 0
                                  ? Icons.waving_hand_outlined
                                  : Icons.location_on_outlined,
                              color: _primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _step == 0
                                ? 'What should we call you?'
                                : 'Where are you based?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _step == 0
                                ? 'Add your name so people on NEE know who they are connecting with.'
                                : 'Choose your work location to find relevant leads and buyers nearby.',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF657080),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_step == 0)
                            Form(
                              key: _nameFormKey,
                              child: AutofillGroup(
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please enter your name to continue.'
                                              : null,
                                  onFieldSubmitted: (_) => _continue(),
                                  decoration: _decoration(
                                    'Your full name',
                                    hint: 'Enter your name',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            OutlinedButton.icon(
                              onPressed: busy ? null : _useCurrentLocation,
                              icon:
                                  _locating
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.my_location_rounded),
                              label: Text(
                                _locating
                                    ? 'Finding your address...'
                                    : 'Use my current location',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                backgroundColor: const Color(0xFFFFF5EF),
                                side: const BorderSide(
                                  color: Color(0xFFFFCCAB),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'At your work location? Use GPS to fill in your address.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF657080),
                              ),
                            ),
                            if (_manual)
                              ..._buildManualEntry()
                            else ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'or search for an address',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF657080),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                              ),
                              TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                enabled: !_locating && !_saving,
                                textInputAction: TextInputAction.search,
                                onChanged: _onSearchChanged,
                                decoration: _decoration(
                                  'Work address or area',
                                  hint: 'e.g. Dispur, Guwahati',
                                  icon: Icons.search_rounded,
                                ).copyWith(
                                  suffixIcon:
                                      _searchCtrl.text.isEmpty
                                          ? null
                                          : IconButton(
                                            tooltip: 'Clear address search',
                                            onPressed:
                                                _locating || _saving
                                                    ? null
                                                    : () {
                                                      _searchCtrl.clear();
                                                      _onSearchChanged('');
                                                      _searchFocus
                                                          .requestFocus();
                                                    },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_searching)
                                const LinearProgressIndicator(color: _primary)
                              else if (_searched &&
                                  _suggestions.isEmpty &&
                                  _error == null &&
                                  !hasLocation)
                                const Text(
                                  'No addresses found. Try a nearby landmark, town or PIN code.',
                                  style: TextStyle(
                                    color: Color(0xFF657080),
                                    height: 1.5,
                                  ),
                                )
                              else if (!hasLocation &&
                                  _suggestions.isEmpty &&
                                  _error == null)
                                const Text(
                                  'Type at least 3 characters, then select a matching address.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF657080),
                                  ),
                                ),
                              if (_suggestions.isNotEmpty)
                                Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E5E9),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      for (final suggestion in _suggestions)
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                          leading: const Icon(
                                            Icons.place_outlined,
                                            color: _primary,
                                          ),
                                          title: Text(
                                            suggestion.description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                          onTap:
                                              () =>
                                                  _selectSuggestion(suggestion),
                                        ),
                                    ],
                                  ),
                                ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (hasLocation) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF7F0),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF287A46),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Location selected',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF287A46),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _resolvedAddress!,
                                              style: const TextStyle(
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Review address details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Edit anything that looks incorrect.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF657080),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _breakdownField(_cityCtrl, 'City / Village'),
                                _breakdownField(_areaCtrl, 'Area (optional)'),
                                _breakdownField(_districtCtrl, 'District'),
                                _breakdownField(_pincodeCtrl, 'PIN code'),
                                _breakdownField(_stateCtrl, 'State'),
                                _breakdownField(_countryCtrl, 'Country'),
                              ],
                              if (!hasLocation) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed:
                                      busy
                                          ? null
                                          : () => setState(() {
                                            _error = null;
                                            _manualNotice = null;
                                            _gpsFix = null;
                                            _enterManualMode();
                                          }),
                                  icon: const Icon(
                                    Icons.edit_location_alt_outlined,
                                  ),
                                  label: const Text(
                                    "Can't find it? Enter address manually",
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primary,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFEAECEF))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_step == 1 && !canContinue && !busy) ...[
                          Text(
                            _manual
                                ? 'Fill in city, district and a 6-digit PIN code to continue.'
                                : 'Select your work location to continue.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF657080),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: canContinue ? _continue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child:
                                _saving
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _step == 0
                                                ? 'Continue to location'
                                                : 'Finish setup',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;
  _PlaceSuggestion({required this.placeId, required this.description});
}
