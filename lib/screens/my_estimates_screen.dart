import '../widgets/app_empty_state.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/estimate_model.dart';
import '../services/api_service.dart';

class MyEstimatesScreen extends StatefulWidget {
  const MyEstimatesScreen({super.key});

  @override
  State<MyEstimatesScreen> createState() => _MyEstimatesScreenState();
}

class _MyEstimatesScreenState extends State<MyEstimatesScreen> {
  List<EstimateModel> _estimates = [];
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
      final data = await apiService.getMyEstimates();
      setState(() {
        _estimates =
            (data['data'] as List)
                .map(
                  (e) => EstimateModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load your estimates. Pull down to retry.';
      });
    }
  }

  static const _statusColors = {
    'submitted': Color(0xFFF9A825),
    'contacted': Color(0xFF1565C0),
    'closed': Color(0xFF2E7D32),
  };

  static const _statusLabels = {
    'submitted': 'Submitted',
    'contacted': 'Contacted',
    'closed': 'Closed',
  };

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('My Estimates')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Could not load estimates',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: _fetch,
              )
              : _estimates.isEmpty
              ? AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No estimates yet',
                message:
                    'Add products to your cart and submit an estimate request. You can track it here.',
                actionLabel: 'Refresh estimates',
                onAction: _fetch,
              )
              : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _estimates.length,
                  itemBuilder: (_, i) {
                    final estimate = _estimates[i];
                    final color = _statusColors[estimate.status] ?? Colors.grey;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EstimateDetailScreen(
                                      estimateId: estimate.id,
                                    ),
                              ),
                            ),
                        title: Text(
                          'Estimate #${estimate.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${estimate.itemCount} item${estimate.itemCount == 1 ? '' : 's'} · ${_formatDate(estimate.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${estimate.grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _statusLabels[estimate.status] ??
                                    estimate.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class EstimateDetailScreen extends StatefulWidget {
  final int estimateId;
  const EstimateDetailScreen({super.key, required this.estimateId});

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  EstimateModel? _estimate;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await apiService.getEstimate(widget.estimateId);
      setState(() {
        _estimate = EstimateModel.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load this estimate.';
      });
    }
  }

  Future<void> _downloadInvoice() async {
    setState(() => _downloading = true);
    try {
      final bytes = await apiService.getEstimatePdfBytes(widget.estimateId);
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'estimate-${widget.estimateId}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not download the invoice. Try again.'),
        ),
      );
    }
    if (mounted) setState(() => _downloading = false);
  }

  Future<void> _showSendEmailSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SendEmailSheet(estimateId: widget.estimateId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    return Scaffold(
      appBar: AppBar(
        title: Text('Estimate #${widget.estimateId}'),
        actions: [
          if (estimate != null) ...[
            IconButton(
              icon:
                  _downloading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.download_outlined),
              tooltip: 'Download Invoice',
              onPressed: _downloading ? null : _downloadInvoice,
            ),
            IconButton(
              icon: const Icon(Icons.email_outlined),
              tooltip: 'Send by Email',
              onPressed: _showSendEmailSheet,
            ),
          ],
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || estimate == null
              ? Center(
                child: Text(
                  _error ?? 'Not found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ...estimate.items.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.quantity} ${item.unit} × ₹${item.unitPrice.toStringAsFixed(0)}',
                        ),
                        trailing: Text(
                          '₹${item.lineTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      Text(
                        '₹${estimate.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST @ ${estimate.taxRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${estimate.taxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${estimate.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  if ((estimate.contactPhone?.isNotEmpty ?? false) ||
                      (estimate.contactEmail?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Contact for This Order',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (estimate.contactPhone?.isNotEmpty ?? false)
                      Text(estimate.contactPhone!),
                    if (estimate.contactEmail?.isNotEmpty ?? false)
                      Text(estimate.contactEmail!),
                  ],
                  if ((estimate.billingAddress?.isNotEmpty ?? false) ||
                      (estimate.shippingAddress?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    if (estimate.billingAddress?.isNotEmpty ?? false) ...[
                      Text(
                        'Billing Address',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${estimate.billingAddress!}${estimate.billingPincode?.isNotEmpty ?? false ? ' — ${estimate.billingPincode}' : ''}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (estimate.shippingAddress?.isNotEmpty ?? false) ...[
                      Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${estimate.shippingAddress!}${estimate.shippingPincode?.isNotEmpty ?? false ? ' — ${estimate.shippingPincode}' : ''}',
                      ),
                    ],
                  ],
                  if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(estimate.notes!),
                  ],
                ],
              ),
    );
  }
}

/// Lets the buyer send this estimate's invoice PDF to one or more email
/// addresses of their choosing — every attempt is logged for admin visibility.
class _SendEmailSheet extends StatefulWidget {
  final int estimateId;
  const _SendEmailSheet({required this.estimateId});

  @override
  State<_SendEmailSheet> createState() => _SendEmailSheetState();
}

class _SendEmailSheetState extends State<_SendEmailSheet> {
  final _emails = <String>[];
  final _inputCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _addEmail() {
    final value = _inputCtrl.text.trim();
    if (value.isEmpty) return;
    if (!_emailRegex.hasMatch(value)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    if (_emails.contains(value)) {
      _inputCtrl.clear();
      return;
    }
    setState(() {
      _emails.add(value);
      _inputCtrl.clear();
      _error = null;
    });
  }

  Future<void> _send() async {
    _addEmail(); // pick up anything left typed but not yet added
    if (_emails.isEmpty) {
      setState(() => _error = 'Add at least one email address');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await apiService.sendEstimateEmail(widget.estimateId, _emails);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estimate sent to ${_emails.length} email${_emails.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send the estimate. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Estimate by Email',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one or more recipients — you can send it to yourself and others.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (_emails.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  _emails
                      .map(
                        (e) => Chip(
                          label: Text(e, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _emails.remove(e)),
                        ),
                      )
                      .toList(),
            ),
          if (_emails.isNotEmpty) const SizedBox(height: 10),
          TextField(
            controller: _inputCtrl,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _addEmail(),
            decoration: InputDecoration(
              labelText: 'Email address',
              errorText: _error,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addEmail,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              child:
                  _sending
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
