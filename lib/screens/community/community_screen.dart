import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../widgets/community_video_player.dart';
import 'compose_post_screen.dart';
import 'post_comments_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<CommunityProvider>();
      if (prov.posts.isEmpty) prov.fetch(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Community'),
          // Community is a bottom-nav tab, not a pushed route — there's
          // nothing on the Navigator stack to pop. MainShell wraps itself
          // in PopScope(canPop: false, ...) precisely so both the
          // hardware back button AND a call here fall through to the same
          // "switch back to the Home tab" handling, instead of exiting
          // the app or doing nothing.
          leading: IconButton(
            tooltip: 'Back to Home',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final posted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ComposePostScreen()),
            );
            if (posted == true && context.mounted) {
              prov.fetch(refresh: true);
            }
          },
          backgroundColor: const Color(0xFF2E7D32),
          icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
          label: const Text('New Post', style: TextStyle(color: Colors.white)),
        ),
        body: prov.posts.isEmpty && prov.loading
            ? const Center(child: CircularProgressIndicator())
            : prov.posts.isEmpty && prov.error != null
            ? _CommunityErrorState(
                message: prov.error!,
                onRetry: () => prov.fetch(refresh: true),
              )
            : prov.posts.isEmpty
            ? Center(
                child: Text(
                  'No posts yet — be the first to share!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => prov.fetch(refresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90, top: 8),
                  itemCount: prov.posts.length + (prov.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= prov.posts.length) {
                      prov.fetch();
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return _PostCard(post: prov.posts[i]);
                  },
                ),
              ),
      ),
    );
  }
}

/// Shown instead of "No posts yet" when the fetch actually failed — otherwise
/// a 401/404/500/network error looks identical to a genuinely empty feed,
/// which made "the community feature isn't deployed yet" indistinguishable
/// from "nobody's posted anything."
class _CommunityErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CommunityErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isMine = context.watch<AuthProvider>().user?.id == post.authorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(30),
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      if (post.fieldVisitLeadTitle != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 11,
                              color: Color(0xFF6A1B9A),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'Site visit — ${post.fieldVisitLeadTitle}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF6A1B9A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isMine)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
          ),
          if (post.isSuspended)
            _SuspendedNotice(reason: isMine ? post.suspensionReason : null)
          else ...[
            if (post.media.isNotEmpty) _MediaCarousel(media: post.media),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        context.read<CommunityProvider>().toggleLike(post.id),
                    child: Row(
                      children: [
                        Icon(
                          post.likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: post.likedByMe ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostCommentsScreen(postId: post.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 19,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.commentsCount}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (post.caption != null && post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${post.authorName} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommunityProvider>().deletePost(post.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Replaces the media, likes/comments and caption of a post an admin has
/// suspended. The reason is only passed in for the author's own post.
class _SuspendedNotice extends StatelessWidget {
  final String? reason;
  const _SuspendedNotice({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.block, size: 36, color: Colors.red[400]),
          const SizedBox(height: 10),
          const Text(
            'This post violates community guidelines',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            'It has been suspended by an admin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: $reason',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaCarousel extends StatefulWidget {
  final List<CommunityMediaItem> media;
  const _MediaCarousel({required this.media});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  int _current = 0;
  final _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.length == 1) {
      return _mediaItem(widget.media.first);
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _mediaItem(widget.media[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.media.asMap().entries.map((e) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == e.key ? Colors.white : Colors.white54,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _mediaItem(CommunityMediaItem item) {
    if (item.isVideo) {
      return CommunityVideoPlayer(url: item.url);
    }
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: item.url,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, _, _) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}
