import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  /// Set by AuthProvider's constructor. Fires whenever any request comes back
  /// {"code": "ACCOUNT_FROZEN"} (EnsureNotFrozen on the backend) — lets the
  /// router jump straight to the blocking screen instead of waiting for the
  /// next full profile refresh to notice.
  void Function(String message)? onAccountFrozen;

  /// Set by AuthProvider's constructor. Fires whenever a request comes back
  /// {"code": "PHONE_NOT_VERIFIED"} (EnsurePhoneVerified on the backend) — a
  /// Google sign-in that hasn't verified a phone number yet tried a feature.
  void Function()? onPhoneNotVerified;

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
        final data = error.response?.data;
        if (error.response?.statusCode == 403 && data is Map && data['code'] == 'ACCOUNT_FROZEN') {
          onAccountFrozen?.call(data['message']?.toString() ?? 'Your account access is currently paused.');
        }
        if (error.response?.statusCode == 403 && data is Map && data['code'] == 'PHONE_NOT_VERIFIED') {
          onPhoneNotVerified?.call();
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

  // Referral
  Future<Map<String, dynamic>> trackReferral(String referralCode) async {
    final res = await _dio.post('/referrals/track', data: {'referral_code': referralCode});
    return res.data;
  }

  Future<Map<String, dynamic>> getReferralStats() async {
    final res = await _dio.get('/referrals/stats');
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

  /// Exchange a Google ID token for an app session.
  Future<Map<String, dynamic>> loginWithGoogle(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/google', data: data);
    return res.data;
  }

  /// OTP-verify a phone number for the signed-in (Google) account. May come
  /// back {"merged": true, "token": ...} when the number belongs to an
  /// existing account — the session then switches to that account.
  Future<Map<String, dynamic>> verifyPhone(String phone, String otp) async {
    final res = await _dio.post('/auth/verify-phone', data: {'phone': phone, 'otp': otp});
    return res.data;
  }

  /// Send OTP to the given phone number via Fast2SMS.
  Future<void> sendOtp(String phone) async {
    await _dio.post('/auth/send-otp', data: {'phone': phone});
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

  Future<Map<String, dynamic>> submitEstimate(
    List<Map<String, dynamic>> items, {
    String? notes,
    String? billingAddress,
    String? billingPincode,
    String? shippingAddress,
    String? shippingPincode,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final res = await _dio.post('/product-estimates', data: {
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (billingAddress != null && billingAddress.isNotEmpty) 'billing_address': billingAddress,
      if (billingPincode != null && billingPincode.isNotEmpty) 'billing_pincode': billingPincode,
      if (shippingAddress != null && shippingAddress.isNotEmpty) 'shipping_address': shippingAddress,
      if (shippingPincode != null && shippingPincode.isNotEmpty) 'shipping_pincode': shippingPincode,
      if (contactPhone != null && contactPhone.isNotEmpty) 'contact_phone': contactPhone,
      if (contactEmail != null && contactEmail.isNotEmpty) 'contact_email': contactEmail,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyEstimates({int page = 1}) async {
    final res = await _dio.get('/product-estimates', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> getEstimate(int id) async {
    final res = await _dio.get('/product-estimates/$id');
    return res.data;
  }

  Future<List<int>> getEstimatePdfBytes(int id) async {
    final res = await _dio.get<List<int>>(
      '/product-estimates/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> sendEstimateEmail(int id, List<String> emails) async {
    final res = await _dio.post('/product-estimates/$id/send-email', data: {'emails': emails});
    return res.data;
  }

  /// A buyer's full construction-project brief (distinct from the cart-based
  /// product estimates above) — structured fields plus free-text notes and
  /// an optional voice memo recorded on-device (local file path).
  Future<Map<String, dynamic>> submitEstimateRequest(
    Map<String, dynamic> data, {
    String? voiceMemoPath,
  }) async {
    if (voiceMemoPath != null) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value != null) formData.fields.add(MapEntry(key, value.toString()));
      });
      formData.files.add(MapEntry(
        'voice_memo',
        await MultipartFile.fromFile(voiceMemoPath, filename: 'voice-memo.m4a'),
      ));
      final res = await _dio.post('/estimate-requests', data: formData);
      return res.data;
    }
    final res = await _dio.post('/estimate-requests', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getMyEstimateRequests({int page = 1}) async {
    final res = await _dio.get('/estimate-requests', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> data, {
    List<XFile>? images,
    List<PlatformFile>? documents,
  }) async {
    final hasFiles = (images != null && images.isNotEmpty) ||
        (documents != null && documents.isNotEmpty);

    if (hasFiles) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      for (final img in images ?? []) {
        final bytes = await img.readAsBytes();
        formData.files.add(MapEntry('images[]',
            MultipartFile.fromBytes(bytes, filename: img.name)));
      }
      for (final doc in documents ?? []) {
        if (doc.bytes != null) {
          formData.files.add(MapEntry('documents[]',
              MultipartFile.fromBytes(doc.bytes!, filename: doc.name)));
        }
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

  Future<Map<String, dynamic>?> getMyWorker() async {
    final res = await _dio.get('/my-worker');
    if (res.data == null) return null;
    return res.data as Map<String, dynamic>;
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
    bool? assignedToMe,
  }) async {
    final res = await _dio.get('/leads', queryParameters: {
      if (type != null) 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
      if (projectType != null) 'project_type': projectType,
      'page': page,
      if (assignedToMe == true) 'assigned_to_me': 1,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> createLead(
    Map<String, dynamic> data, {
    List<XFile>? images,
    List<PlatformFile>? documents,
  }) async {
    final hasFiles = (images != null && images.isNotEmpty) ||
        (documents != null && documents.isNotEmpty);

    if (hasFiles) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      for (final img in images ?? []) {
        final bytes = await img.readAsBytes();
        formData.files.add(MapEntry('images[]',
            MultipartFile.fromBytes(bytes, filename: img.name)));
      }
      for (final doc in documents ?? []) {
        if (doc.bytes != null) {
          formData.files.add(MapEntry('documents[]',
              MultipartFile.fromBytes(doc.bytes!, filename: doc.name)));
        }
      }
      final res = await _dio.post('/leads', data: formData);
      return res.data;
    }
    final res = await _dio.post('/leads', data: data);
    return res.data;
  }

  // Lead packages & exclusive claims
  Future<Map<String, dynamic>> getLeadPackages() async {
    final res = await _dio.get('/lead-packages');
    return res.data;
  }

  Future<Map<String, dynamic>> getMyLeadSubscription() async {
    final res = await _dio.get('/lead-packages/my-subscription');
    return res.data;
  }

  Future<Map<String, dynamic>> purchaseLeadPackage(int packageId) async {
    final res = await _dio.post('/lead-packages/$packageId/purchase');
    return res.data;
  }

  Future<Map<String, dynamic>> verifyLeadPackagePayment(
    int purchaseId, {
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final res = await _dio.post('/lead-packages/purchases/$purchaseId/verify', data: {
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': orderId,
      'razorpay_signature': signature,
    });
    return res.data;
  }

  /// Throws a [DioException] with status 402 when an active lead package is
  /// required (response body contains the available `packages`).
  Future<Map<String, dynamic>> proceedWithLead(int leadId) async {
    final res = await _dio.post('/leads/$leadId/proceed');
    return res.data;
  }

  Future<Map<String, dynamic>> getMyLeadClaims({int page = 1}) async {
    final res = await _dio.get('/my-lead-claims', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> submitClaimFeedback(int claimId,
      {required bool converted, String? comment}) async {
    final res = await _dio.post('/lead-claims/$claimId/feedback', data: {
      'converted': converted,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
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

  Future<Map<String, dynamic>> applyJob(int jobId, Map<String, dynamic> data, {PlatformFile? cv}) async {
    if (cv != null && cv.bytes != null) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value != null) formData.fields.add(MapEntry(key, value.toString()));
      });
      formData.files.add(MapEntry('cv', MultipartFile.fromBytes(cv.bytes!, filename: cv.name)));
      final res = await _dio.post('/jobs/$jobId/apply', data: formData);
      return res.data;
    }
    final res = await _dio.post('/jobs/$jobId/apply', data: data);
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

  // Suppliers
  Future<Map<String, dynamic>> getSuppliers({String? search, String? location, int page = 1, int perPage = 30}) async {
    final res = await _dio.get('/suppliers', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null) 'location': location,
      'page': page,
      'per_page': perPage,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getSupplier(int id) async {
    final res = await _dio.get('/suppliers/$id');
    return res.data;
  }

  // Business support
  Future<List<dynamic>> getBusinessTypes() async {
    final res = await _dio.get('/business-types');
    return res.data as List;
  }

  Future<Map<String, dynamic>> requestBusinessConsultation(Map<String, dynamic> data, {PlatformFile? document}) async {
    if (document != null && document.bytes != null) {
      final formData = FormData();
      data.forEach((key, value) {
        if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      formData.files.add(MapEntry('document', MultipartFile.fromBytes(document.bytes!, filename: document.name)));
      final res = await _dio.post('/business-consultations', data: formData);
      return res.data;
    }
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

  // Telecaller lead screening
  Future<Map<String, dynamic>> getTelecallerLeadPool({
    String? search,
    String? projectType,
    int page = 1,
  }) async {
    final res = await _dio.get('/telecaller/leads', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (projectType != null) 'project_type': projectType,
      'page': page,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyTelecallerLeads({int page = 1}) async {
    final res = await _dio.get('/telecaller/my-leads', queryParameters: {'page': page});
    return res.data;
  }

  /// Every lead this telecaller has ever logged a call outcome for — see
  /// TelecallerLeadController::processedLeads. Optionally filtered to one
  /// outcome (hot/cold/callback/archive/closed).
  Future<Map<String, dynamic>> getProcessedTelecallerLeads({String? status, int page = 1}) async {
    final res = await _dio.get('/telecaller/processed-leads', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> claimTelecallerLead(int leadId) async {
    final res = await _dio.post('/telecaller/leads/$leadId/claim');
    return res.data;
  }

  Future<void> releaseTelecallerLead(int leadId) async {
    await _dio.post('/telecaller/leads/$leadId/release');
  }

  Future<Map<String, dynamic>> submitTelecallerCallLog(
    int leadId, {
    required String status,
    String? nextFollowUpAt,
    String? comment,
    Map<String, dynamic>? projectDetails,
  }) async {
    final res = await _dio.post('/telecaller/leads/$leadId/call-log', data: {
      'status': status,
      if (nextFollowUpAt != null) 'next_follow_up_at': nextFollowUpAt,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      ...?projectDetails,
    });
    return res.data;
  }

  /// Call log history plus the shared project-details questionnaire for a
  /// lead — viewable by both Area Managers and Lead Managers.
  Future<Map<String, dynamic>> getLeadCallHistory(int leadId) async {
    final res = await _dio.get('/leads/$leadId/call-history');
    return res.data;
  }

  Future<Map<String, dynamic>> scheduleFieldVisit(
    int leadId,
    String scheduledDate, {
    int? leadManagerId,
  }) async {
    final res = await _dio.post('/telecaller/leads/$leadId/field-visit', data: {
      'scheduled_date': scheduledDate,
      if (leadManagerId != null) 'lead_manager_id': leadManagerId,
    });
    return res.data;
  }

  /// Lead managers who could take this lead's field visit, district-matched ones flagged.
  Future<List<dynamic>> getEligibleLeadManagers(int leadId) async {
    final res = await _dio.get('/telecaller/leads/$leadId/eligible-lead-managers');
    return res.data as List;
  }

  Future<void> cancelFieldVisit(int visitId) async {
    await _dio.post('/telecaller/field-visits/$visitId/cancel');
  }

  /// Field visits this Area Manager scheduled/assigned — lets them track
  /// status (pending/accepted/declined/completed) after handing a lead off.
  Future<Map<String, dynamic>> getMyScheduledFieldVisits({int page = 1}) async {
    final res = await _dio.get('/telecaller/field-visits', queryParameters: {'page': page});
    return res.data;
  }

  /// Every lead manager, with how many of this Area Manager's visits are
  /// currently on each one's plate — for the "Lead Managers" dashboard tab
  /// and for picking who to reassign a declined visit to.
  Future<List<dynamic>> getLeadManagers() async {
    final res = await _dio.get('/telecaller/lead-managers');
    return res.data as List;
  }

  /// Area Manager hands a declined visit to a different lead manager, for the
  /// same scheduled date unless a new one is given.
  Future<Map<String, dynamic>> reassignFieldVisit(
    int visitId,
    int leadManagerId, {
    String? scheduledDate,
  }) async {
    final res = await _dio.post('/telecaller/field-visits/$visitId/reassign', data: {
      'lead_manager_id': leadManagerId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
    });
    return res.data;
  }

  // Field visits (app user side)
  /// Throws a [DioException] with status 402 when an active lead package is
  /// required (same gate as [proceedWithLead]).
  Future<Map<String, dynamic>> acceptFieldVisit(int visitId) async {
    final res = await _dio.post('/field-visits/$visitId/accept');
    return res.data;
  }

  /// Raise a concern that this visit can't be made — frees it up for the
  /// Area Manager to reassign, releasing any lead claim already held.
  Future<Map<String, dynamic>> declineFieldVisit(int visitId, {String? reason}) async {
    final res = await _dio.post('/field-visits/$visitId/decline', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> submitFieldVisitReport(
    int visitId,
    Map<String, dynamic> data, {
    List<XFile>? photos,
  }) async {
    final formData = FormData();
    data.forEach((key, value) {
      if (value is bool) {
        formData.fields.add(MapEntry(key, value ? '1' : '0'));
      } else if (value is List) {
        // Multipart form fields can't carry a real array — Dio's default
        // toString() on a List (e.g. work_stage) would send the literal
        // text "[a, b]" as one field instead of separate array entries, so
        // Laravel would never see it as a list. Use the same key[] repeated
        // notation already used for photos[] below.
        for (final item in value) {
          formData.fields.add(MapEntry('$key[]', item.toString()));
        }
      } else if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });
    for (final photo in photos ?? []) {
      final bytes = await photo.readAsBytes();
      formData.files.add(MapEntry('photos[]', MultipartFile.fromBytes(bytes, filename: photo.name)));
    }
    final res = await _dio.post('/field-visits/$visitId/report', data: formData);
    return res.data;
  }

  Future<Map<String, dynamic>> getMyFieldVisits({int page = 1}) async {
    final res = await _dio.get('/my-field-visits', queryParameters: {'page': page});
    return res.data;
  }

  // Community
  Future<Map<String, dynamic>> getCommunityPosts({int page = 1}) async {
    final res = await _dio.get('/community/posts', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> createCommunityPost({
    String? caption,
    List<XFile>? photos,
    List<XFile>? videos,
    int? leadFieldVisitId,
  }) async {
    final formData = FormData();
    if (caption != null && caption.isNotEmpty) {
      formData.fields.add(MapEntry('caption', caption));
    }
    if (leadFieldVisitId != null) {
      formData.fields.add(MapEntry('lead_field_visit_id', leadFieldVisitId.toString()));
    }
    for (final photo in photos ?? []) {
      final bytes = await photo.readAsBytes();
      formData.files.add(MapEntry('photos[]', MultipartFile.fromBytes(bytes, filename: photo.name)));
    }
    for (final video in videos ?? []) {
      final bytes = await video.readAsBytes();
      formData.files.add(MapEntry('videos[]', MultipartFile.fromBytes(bytes, filename: video.name)));
    }
    final res = await _dio.post('/community/posts', data: formData);
    return res.data;
  }

  Future<void> deleteCommunityPost(int postId) async {
    await _dio.delete('/community/posts/$postId');
  }

  Future<Map<String, dynamic>> toggleCommunityLike(int postId) async {
    final res = await _dio.post('/community/posts/$postId/like');
    return res.data;
  }

  Future<Map<String, dynamic>> getCommunityComments(int postId, {int page = 1}) async {
    final res = await _dio.get('/community/posts/$postId/comments', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> addCommunityComment(int postId, String comment) async {
    final res = await _dio.post('/community/posts/$postId/comments', data: {'comment': comment});
    return res.data;
  }

  Future<void> deleteCommunityComment(int commentId) async {
    await _dio.delete('/community/comments/$commentId');
  }

  // Points & Rewards
  Future<Map<String, dynamic>> getWalletBalance() async {
    final res = await _dio.get('/wallet');
    return res.data;
  }

  Future<Map<String, dynamic>> getPointsTransactions({int page = 1}) async {
    final res = await _dio.get('/wallet/transactions', queryParameters: {'page': page});
    return res.data;
  }

  Future<List<dynamic>> getRewards() async {
    final res = await _dio.get('/rewards');
    return res.data as List;
  }

  Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    final res = await _dio.post('/rewards/$rewardId/redeem');
    return res.data;
  }

  Future<Map<String, dynamic>> getMyRedemptions({int page = 1}) async {
    final res = await _dio.get('/my-redemptions', queryParameters: {'page': page});
    return res.data;
  }

  // Role change requests
  Future<Map<String, dynamic>> requestRoleChange(String role) async {
    final res = await _dio.post('/role-requests', data: {'role': role});
    return res.data;
  }

  Future<Map<String, dynamic>> getMyRoleRequests({int page = 1}) async {
    final res = await _dio.get('/my-role-requests', queryParameters: {'page': page});
    return res.data;
  }

  // Associate partner — read-only oversight dashboard
  Future<Map<String, dynamic>> getAssociatePartnerOverview() async {
    final res = await _dio.get('/associate-partner/overview');
    return res.data;
  }

  Future<Map<String, dynamic>> getStaffCallLogs(int userId, {int page = 1}) async {
    final res = await _dio.get('/associate-partner/staff/$userId/call-logs', queryParameters: {'page': page});
    return res.data;
  }

  Future<Map<String, dynamic>> getStaffFieldVisits(int userId, {int page = 1}) async {
    final res = await _dio.get('/associate-partner/staff/$userId/field-visits', queryParameters: {'page': page});
    return res.data;
  }
}

// Global singleton
final apiService = ApiService();
