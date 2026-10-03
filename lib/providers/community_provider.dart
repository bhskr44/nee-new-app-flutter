import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/community_post_model.dart';
import '../services/api_service.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPostModel> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  List<CommunityPostModel> get posts => _posts;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Surfaces *why* loading failed instead of a generic message — swallowing
  /// this previously made "the backend isn't deployed yet" and "the feed is
  /// genuinely empty" look identical (both just showed "No posts yet").
  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage =
        e.response?.data is Map
            ? e.response?.data['message']?.toString()
            : null;
    if (status == 401) return 'Session expired — please log in again.';
    if (status == 404) {
      return 'Community feature not found on the server (404) — it may not be deployed yet.';
    }
    if (status != null && status >= 500) {
      return 'Server error ($status) — the backend may not be fully set up yet.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection.';
    }
    return serverMessage ?? 'Failed to load the community feed.';
  }

  Future<void> fetch({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _posts = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getCommunityPosts(page: _page);
      final items =
          (data['data'] as List)
              .map((e) => CommunityPostModel.fromJson(e))
              .toList();
      _posts = refresh ? items : [..._posts, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } on DioException catch (e) {
      _error = _describeError(e);
    } catch (_) {
      _error = 'Failed to load the community feed.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Returns null on success, or an error message describing why posting failed.
  Future<String?> createPost({
    String? caption,
    List<XFile>? photos,
    List<XFile>? videos,
    int? leadFieldVisitId,
  }) async {
    try {
      await apiService.createCommunityPost(
        caption: caption,
        photos: photos,
        videos: videos,
        leadFieldVisitId: leadFieldVisitId,
      );
      fetch(refresh: true);
      return null;
    } on DioException catch (e) {
      return _describeError(e);
    } catch (_) {
      return 'Could not post. Try again.';
    }
  }

  Future<void> toggleLike(int postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    // Optimistic update
    final post = _posts[index];
    final optimisticLiked = !post.likedByMe;
    _posts[index] = post.copyWith(
      likedByMe: optimisticLiked,
      likesCount: post.likesCount + (optimisticLiked ? 1 : -1),
    );
    notifyListeners();

    try {
      final res = await apiService.toggleCommunityLike(postId);
      final i = _posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        _posts[i] = _posts[i].copyWith(
          likedByMe: res['liked'] == true,
          likesCount: res['likes_count'],
        );
        notifyListeners();
      }
    } catch (_) {
      // revert on failure
      final i = _posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        _posts[i] = post;
        notifyListeners();
      }
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      await apiService.deleteCommunityPost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void incrementCommentCount(int postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i != -1) {
      _posts[i] = _posts[i].copyWith(
        commentsCount: _posts[i].commentsCount + 1,
      );
      notifyListeners();
    }
  }
}
