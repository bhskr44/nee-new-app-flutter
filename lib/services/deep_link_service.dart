import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  GoRouter? _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    // Handle app opened from cold start via deep link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // Handle links while app is running
    _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (_router == null) return;

    final path = uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      _router!.go('/');
      return;
    }

    switch (segments[0]) {
      case 'products':
        if (segments.length > 1) {
          _router!.go('/products/${segments[1]}');
        } else {
          _router!.go('/products');
        }
        break;
      case 'workers':
        if (segments.length > 1) {
          _router!.go('/workers/${segments[1]}');
        } else {
          _router!.go('/workers');
        }
        break;
      case 'leads':
        if (segments.length > 1) {
          _router!.go('/leads/${segments[1]}');
        } else {
          _router!.go('/leads');
        }
        break;
      case 'jobs':
        _router!.go('/jobs');
        break;
      case 'notifications':
        _router!.go('/notifications');
        break;
      default:
        _router!.go('/');
    }
  }

  /// Generate a shareable deep link URL for any content
  static String buildShareLink(String type, String id) {
    return 'neeconstruction://app/$type/$id';
  }

  static String buildWebLink(String baseUrl, String type, String id) {
    return '$baseUrl/app/$type/$id';
  }
}

final deepLinkService = DeepLinkService();
