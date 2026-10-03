import '../widgets/app_search_field.dart';
import '../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/supplier_model.dart';
import '../services/api_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<SupplierModel> _suppliers = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _search = '';
  String? _error;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _fetch();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if ((_loading || !_hasMore) && !refresh) return;
    final version = ++_requestVersion;
    _error = null;
    if (refresh) {
      setState(() {
        _suppliers = [];
        _page = 1;
        _hasMore = true;
      });
    }
    setState(() => _loading = true);
    try {
      final res = await apiService.getSuppliers(
        search: _search.isEmpty ? null : _search,
        page: refresh ? 1 : _page,
      );
      if (!mounted || version != _requestVersion) return;
      final items =
          (res['data'] as List?)
              ?.map((e) => SupplierModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final meta = res['meta'] as Map? ?? res;
      final lastPage = meta['last_page'] ?? 1;
      setState(() {
        if (refresh || _page == 1) {
          _suppliers = items;
        } else {
          _suppliers = [..._suppliers, ...items];
        }
        _hasMore = _page < lastPage;
        _page = (refresh ? 1 : _page) + 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _loading = false;
        _error = 'Check your connection and try again.';
      });
    }
  }

  void _onSearch(String val) {
    _search = val;
    _fetch(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Suppliers'),
        backgroundColor: const Color(0xFFBF360C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetch(refresh: true),
              child:
                  _suppliers.isEmpty && _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _suppliers.isEmpty
                      ? AppEmptyState(
                        icon: Icons.store_outlined,
                        title:
                            _error != null
                                ? 'Could not load suppliers'
                                : 'No suppliers found',
                        message: _error ?? 'Try another supplier name or city.',
                        actionLabel: 'Refresh suppliers',
                        onAction: () => _fetch(refresh: true),
                      )
                      : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: _suppliers.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _suppliers.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child:
                                    _loading
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                          onPressed: () => _fetch(),
                                          child: Text(
                                            _error != null
                                                ? 'Try loading more again'
                                                : 'Load more suppliers',
                                          ),
                                        ),
                              ),
                            );
                          }
                          return _SupplierCard(supplier: _suppliers[i]);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppSearchField(
        controller: _searchCtrl,
        hint: 'Search suppliers or cities',
        onChanged: _onSearch,
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFFE65100),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (supplier.location != null &&
                        supplier.location!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          Expanded(
                            child: Text(
                              supplier.location!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (supplier.productsCount != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${supplier.productsCount} products',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (supplier.phone != null && supplier.phone!.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    color: Color(0xFFE65100),
                    size: 20,
                  ),
                  onPressed: () => _callPhone(context, supplier.phone!),
                  tooltip: 'Call',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Color(0xFFE65100),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (supplier.location != null &&
                              supplier.location!.isNotEmpty)
                            Text(
                              supplier.location!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                if (supplier.phone != null && supplier.phone!.isNotEmpty)
                  _infoRow(Icons.phone, supplier.phone!),
                if (supplier.email != null && supplier.email!.isNotEmpty)
                  _infoRow(Icons.email_outlined, supplier.email!),
                if (supplier.address != null && supplier.address!.isNotEmpty)
                  _infoRow(Icons.home_outlined, supplier.address!),
                if (supplier.website != null && supplier.website!.isNotEmpty)
                  _infoRow(Icons.language, supplier.website!),
                if (supplier.productsCount != null)
                  _infoRow(
                    Icons.inventory_2_outlined,
                    '${supplier.productsCount} products listed',
                  ),
                const SizedBox(height: 16),
                if (supplier.phone != null && supplier.phone!.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _callPhone(context, supplier.phone!);
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final clean = supplier.phone!.replaceAll(
                              RegExp(r'[^\d]'),
                              '',
                            );
                            final uri = Uri.parse('https://wa.me/91$clean');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
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

  Widget _infoRow(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE65100)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
