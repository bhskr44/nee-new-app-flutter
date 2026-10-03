import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';

/// Standalone "New Post" flow. When [leadFieldVisitId] is set (e.g. right
/// after filing a field-visit report), the post is tagged as coming from
/// that site visit and [initialPhotos] pre-fills the picked images.
class ComposePostScreen extends StatefulWidget {
  final int? leadFieldVisitId;
  final List<XFile>? initialPhotos;

  const ComposePostScreen({
    super.key,
    this.leadFieldVisitId,
    this.initialPhotos,
  });

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _photos = [];
  List<XFile> _videos = [];
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _photos = widget.initialPhotos ?? [];
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() => _photos = [..._photos, ...imgs].take(6).toList());
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      setState(() => _videos = [..._videos, video].take(2).toList());
    }
  }

  Future<void> _post() async {
    if (_photos.isEmpty && _videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one photo or video.')),
      );
      return;
    }
    setState(() => _posting = true);

    final error = await context.read<CommunityProvider>().createPost(
      caption: _captionCtrl.text.trim(),
      photos: _photos.isEmpty ? null : _photos,
      videos: _videos.isEmpty ? null : _videos,
      leadFieldVisitId: widget.leadFieldVisitId,
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _post,
            child:
                _posting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.leadFieldVisitId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, size: 15, color: Color(0xFF6A1B9A)),
                    SizedBox(width: 6),
                    Text(
                      'Tagged as a site visit',
                      style: TextStyle(
                        color: Color(0xFF6A1B9A),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's happening on site?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Photos (${_photos.length}/6)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photos.asMap().entries.map(
                  (e) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder(
                            future: e.value.readAsBytes(),
                            builder:
                                (_, snap) =>
                                    snap.hasData
                                        ? Image.memory(
                                          snap.requireData,
                                          fit: BoxFit.cover,
                                        )
                                        : const SizedBox(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(e.key)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_photos.length < 6)
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey[500],
                            size: 24,
                          ),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Video (${_videos.length}/2)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._videos.asMap().entries.map(
                  (e) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black87,
                        ),
                        child: const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _videos.removeAt(e.key)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_videos.length < 2)
                  GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_call_outlined,
                            color: Colors.grey[500],
                            size: 24,
                          ),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
