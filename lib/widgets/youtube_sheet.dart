import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void showYoutubeSheet(BuildContext context, String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null ||
      (!uri.host.contains('youtube.com') && !uri.host.contains('youtu.be'))) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid YouTube URL')),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.6,
      child: _YoutubeSheet(url: url.trim()),
    ),
  );
}

class _YoutubeSheet extends StatefulWidget {
  final String url;
  const _YoutubeSheet({required this.url});
  @override
  State<_YoutubeSheet> createState() => __YoutubeSheetState();
}

class __YoutubeSheetState extends State<_YoutubeSheet> {
  late final WebViewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: WebViewWidget(controller: _ctrl)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
