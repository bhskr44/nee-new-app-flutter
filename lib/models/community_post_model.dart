class CommunityMediaItem {
  final String type; // 'photo' | 'video'
  final String url;

  const CommunityMediaItem({required this.type, required this.url});

  bool get isVideo => type == 'video';

  factory CommunityMediaItem.fromJson(Map<String, dynamic> j) =>
      CommunityMediaItem(type: j['type'] ?? 'photo', url: j['url'] ?? '');
}

/// A signed-up-but-never-completed-onboarding account can have a blank
/// `users.name` (see AuthController — a placeholder like "User 1234" gets
/// cleared to force the name/address screen again) — `??` alone only
/// catches a missing key, not an empty string, so that showed up here as a
/// blank name and a bare "?" avatar initial.
String _authorName(Map<String, dynamic>? user) {
  final name = user?['name'] as String?;
  return (name == null || name.trim().isEmpty) ? 'Someone' : name;
}

class CommunityPostModel {
  final int id;
  final String? caption;
  final String authorName;
  final int authorId;
  final List<CommunityMediaItem> media;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final String? fieldVisitLeadTitle;
  final String createdAt;

  /// Set by admin moderation — the backend withholds caption/media for a
  /// suspended post, and the feed shows a guidelines notice in their place.
  final bool isSuspended;
  final String? suspensionReason;

  const CommunityPostModel({
    required this.id,
    this.caption,
    required this.authorName,
    required this.authorId,
    required this.media,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    this.fieldVisitLeadTitle,
    required this.createdAt,
    this.isSuspended = false,
    this.suspensionReason,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return CommunityPostModel(
      id: j['id'],
      caption: j['caption'],
      authorName: _authorName(user),
      authorId: user?['id'] ?? 0,
      media: (j['media_urls'] as List? ?? [])
          .map((e) => CommunityMediaItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
      likedByMe: j['liked_by_me'] == true,
      fieldVisitLeadTitle: j['field_visit']?['lead']?['title'],
      createdAt: j['created_at'] ?? '',
      isSuspended: j['is_suspended'] == true,
      suspensionReason: j['suspension_reason'],
    );
  }

  CommunityPostModel copyWith({
    bool? likedByMe,
    int? likesCount,
    int? commentsCount,
  }) => CommunityPostModel(
    id: id,
    caption: caption,
    authorName: authorName,
    authorId: authorId,
    media: media,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    likedByMe: likedByMe ?? this.likedByMe,
    fieldVisitLeadTitle: fieldVisitLeadTitle,
    createdAt: createdAt,
    isSuspended: isSuspended,
    suspensionReason: suspensionReason,
  );
}

class CommunityCommentModel {
  final int id;
  final String authorName;
  final String comment;
  final String createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.authorName,
    required this.comment,
    required this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> j) =>
      CommunityCommentModel(
        id: j['id'],
        authorName: _authorName(j['user'] as Map<String, dynamic>?),
        comment: j['comment'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}
