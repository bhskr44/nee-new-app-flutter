import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          StorageService.deleteToken();
        }
        handler.next(error);
      },
    ));
  }

  // Auth
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/login', data: data);
    return res.data;
  }

  /// Login or register via TrueCaller-verified phone number.
  Future<Map<String, dynamic>> loginWithPhone(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/phone-login', data: data);
    return res.data;
  }

  Future<void> logout({String? fcmToken}) async {
    await _dio.post('/auth/logout', data: {'fcm_token': fcmToken});
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/auth/profile', data: data);
    return res.data;
  }

  Future<void> registerFcmToken(String token, String platform) async {
    await _dio.post('/auth/fcm-token', data: {'fcm_token': token, 'platform': platform});
  }

  Future<void> changePassword(Map<String, dynamic> data) async {
    await _dio.post('/auth/change-password', data: data);
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard/stats');
    return res.data;
  }

  Future<Map<String, dynamic>> getFeatured() async {
    final res = await _dio.get('/dashboard/featured');
    return res.data;
  }

  Future<List<dynamic>> getSliders() async {
    final res = await _dio.get('/dashboard/sliders');
    return res.data as List;
  }

  Future<Map<String, dynamic>> getDynamicLink(String type, String id) async {
    final res = await _dio.get('/dynamic-link', queryParameters: {'type': type, 'id': id});
    return res.data;
  }

  // Products
  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    String? location,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _dio.get('/products', queryParameters: {
      if (category != null && category != 'All') 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null) 'location': location,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      'page': page,
      'per_page': perPage,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final res = await _dio.get('/products/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data, {List<XFile>? images}) async {
    if (images != null && images.isNotEmpty) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      for (final img in images) {
        final bytes = await img.readAsBytes();
        formData.files.add(MapEntry('images[]',
            MultipartFile.fromBytes(bytes, filename: img.name)));
      }
      final res = await _dio.post('/products', data: formData);
      return res.data;
    }
    final res = await _dio.post('/products', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return res.data;
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete('/products/$id');
  }

  // Workers
  Future<Map<String, dynamic>> getWorkers({
    String? trade,
    String? search,
    String? location,
    bool? available,
    double? maxRate,
    int page = 1,
  }) async {
    final res = await _dio.get('/workers', queryParameters: {
      if (trade != null && trade != 'All') 'trade': trade,
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null) 'location': location,
      if (available != null) 'available': available ? '1' : '0',
      if (maxRate != null) 'max_rate': maxRate,
      'page': page,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> createWorker(Map<String, dynamic> data) async {
    final res = await _dio.post('/workers', data: data);
    return res.data;
  }

  // Leads
  Future<Map<String, dynamic>> getLeads({
    String? type,
    String? search,
    String? projectType,
    int page = 1,
  }) async {
    final res = await _dio.get('/leads', queryParameters: {
      if (type != null) 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
      if (projectType != null) 'project_type': projectType,
      'page': page,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data, {List<XFile>? images}) async {
    if (images != null && images.isNotEmpty) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      for (final img in images) {
        final bytes = await img.readAsBytes();
        formData.files.add(MapEntry('images[]',
            MultipartFile.fromBytes(bytes, filename: img.name)));
      }
      final res = await _dio.post('/leads', data: formData);
      return res.data;
    }
    final res = await _dio.post('/leads', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getLeadFeedbacks(int leadId) async {
    final res = await _dio.get('/leads/$leadId/feedbacks');
    return res.data;
  }

  Future<Map<String, dynamic>> submitLeadFeedback(int leadId, Map<String, dynamic> data) async {
    final res = await _dio.post('/leads/$leadId/feedback', data: data);
    return res.data;
  }

  // Jobs
  Future<Map<String, dynamic>> getJobs({String? search, String? jobType, int page = 1}) async {
    final res = await _dio.get('/jobs', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (jobType != null) 'job_type': jobType,
      'page': page,
    });
    return res.data;
  }

  // Courses
  Future<Map<String, dynamic>> getCourses({String? search, String? mode, int page = 1}) async {
    final res = await _dio.get('/courses', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (mode != null) 'mode': mode,
      'page': page,
    });
    return res.data;
  }

  // Funding
  Future<List<dynamic>> getFunding({String? type, String? search}) async {
    final res = await _dio.get('/funding', queryParameters: {
      if (type != null && type != 'All') 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return res.data as List;
  }

  Future<Map<String, dynamic>> applyFunding(Map<String, dynamic> data) async {
    final res = await _dio.post('/funding/apply', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> applyJob(int jobId, Map<String, dynamic> data) async {
    final res = await _dio.post('/jobs/$jobId/apply', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> enrollCourse(int courseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/courses/$courseId/enroll', data: data);
    return res.data;
  }

  // Area Contacts
  Future<List<dynamic>> getAreaContacts({String? region, String? search}) async {
    final res = await _dio.get('/area-contacts', queryParameters: {
      if (region != null && region != 'All') 'region': region,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return res.data as List;
  }

  // Business support
  Future<List<dynamic>> getBusinessTypes() async {
    final res = await _dio.get('/business-types');
    return res.data as List;
  }

  Future<Map<String, dynamic>> requestBusinessConsultation(Map<String, dynamic> data) async {
    final res = await _dio.post('/business-consultations', data: data);
    return res.data;
  }

  // Activity logging
  Future<void> logActivity({
    required String action,
    String? entityType,
    int? entityId,
    String? entityName,
    Map<String, dynamic>? extra,
  }) async {
    await _dio.post('/activity', data: {
      'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (entityName != null) 'entity_name': entityName,
      if (extra != null) 'extra': extra,
    });
  }

  Future<List<dynamic>> getUserActivity() async {
    final res = await _dio.get('/activity');
    return res.data as List;
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final res = await _dio.get('/notifications', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return res.data;
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/read-all');
  }
}

// Global singleton
final apiService = ApiService();
