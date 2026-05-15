import 'api_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  Future<void> log(
    String action, {
    String? entityType,
    int? entityId,
    String? entityName,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await apiService.logActivity(
        action: action,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        extra: extra,
      );
    } catch (_) {
      // Fire-and-forget — never block the user on logging failures
    }
  }
}

final activityService = ActivityService();
