import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/building_estimate_request_model.dart';
import '../services/api_service.dart';
import '../widgets/app_empty_state.dart';

/// The buyer's own past building-estimate requests — separate from the
/// product-based "My Estimates" screen, since this is a full construction
/// project brief, not a cart of products.
class MyEstimateRequestsScreen extends StatefulWidget {
  const MyEstimateRequestsScreen({super.key});

  @override
  State<MyEstimateRequestsScreen> createState() => _MyEstimateRequestsScreenState();
}

class _MyEstimateRequestsScreenState extends State<MyEstimateRequestsScreen> {
  List<BuildingEstimateRequestModel> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiService.getMyEstimateRequests();
      setState(() {
        _requests = (data['data'] as List)
            .map((e) => BuildingEstimateRequestModel.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load your requests. Pull down to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Estimate Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load this list',
                  message: _error!,
                  actionLabel: 'Try again',
                  onAction: _fetch,
                )
              : _requests.isEmpty
                  ? Center(
                      child: Text("You haven't requested an estimate yet.",
                          style: TextStyle(color: Colors.grey[600])),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (_, i) => _RequestCard(request: _requests[i]),
                      ),
                    ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final BuildingEstimateRequestModel request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final url = widget.request.voiceMemoUrl;
    if (url == null) return;
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(url));
    if (mounted) setState(() => _playing = true);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final color = r.isOpen ? const Color(0xFFF9A825) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  r.projectType ?? 'Building Estimate Request',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  r.isOpen ? 'Open' : 'Closed',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Submitted ${_fmtDate(r.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (r.location != null || r.plotSizeSqft != null || r.floors != null) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 4, children: [
                if (r.location != null) _detail(Icons.location_on_outlined, r.location!),
                if (r.plotSizeSqft != null) _detail(Icons.square_foot_outlined, '${r.plotSizeSqft} sqft'),
                if (r.floors != null) _detail(Icons.layers_outlined, '${r.floors} floor(s)'),
                if (r.roomRequirement != null) _detail(Icons.home_outlined, r.roomRequirement!.toUpperCase()),
              ]),
            ],
            if (r.budgetMin != null || r.budgetMax != null) ...[
              const SizedBox(height: 6),
              Text(
                'Budget: ₹${r.budgetMin ?? 0} – ₹${r.budgetMax ?? 0}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.notes!, style: TextStyle(fontSize: 12.5, color: Colors.grey[800])),
            ],
            if (r.voiceMemoUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: _togglePlayback,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: const Color(0xFF6A1B9A), size: 22),
                  const SizedBox(width: 6),
                  const Text('Voice memo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ]);
}
