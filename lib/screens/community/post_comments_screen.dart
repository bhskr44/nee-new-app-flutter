import '../../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community_post_model.dart';
import '../../providers/community_provider.dart';
import '../../services/api_service.dart';

class PostCommentsScreen extends StatefulWidget {
  final int postId;
  const PostCommentsScreen({super.key, required this.postId});

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _commentCtrl = TextEditingController();
  List<CommunityCommentModel> _comments = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiService.getCommunityComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments =
            (data['data'] as List)
                .map((e) => CommunityCommentModel.fromJson(e))
                .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Check your connection and try again.';
      });
    }
  }

  Future<void> _send() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await apiService.addCommunityComment(widget.postId, text);
      if (!mounted) return;
      _commentCtrl.clear();
      setState(() {
        _comments.add(CommunityCommentModel.fromJson(res['comment']));
        _sending = false;
      });
      context.read<CommunityProvider>().incrementCommentCount(widget.postId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post your comment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? AppEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Could not load comments',
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: _fetch,
                    )
                    : _comments.isEmpty
                    ? Center(
                      child: Text(
                        'No comments yet — be the first.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(
                                  0xFF2E7D32,
                                ).withAlpha(30),
                                child: Text(
                                  c.authorName.isNotEmpty
                                      ? c.authorName[0].toUpperCase()
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
                                      c.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.comment,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Send comment',
                    onPressed: _sending ? null : _send,
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
