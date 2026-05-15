import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/area_contact_model.dart';
import '../providers/area_contact_provider.dart';
import '../services/activity_service.dart';

class AreaContactsScreen extends StatefulWidget {
  const AreaContactsScreen({super.key});

  @override
  State<AreaContactsScreen> createState() => _AreaContactsScreenState();
}

class _AreaContactsScreenState extends State<AreaContactsScreen> {
  static const _regions = [
    'All',
    'Upper Assam',
    'Lower Assam',
    'Central Assam',
    'North Assam',
    'Barak Valley',
    'Hills',
  ];

  static const _regionColors = {
    'Upper Assam': Color(0xFF1565C0),
    'Lower Assam': Color(0xFF2E7D32),
    'Central Assam': Color(0xFF6A1B9A),
    'North Assam': Color(0xFF00695C),
    'Barak Valley': Color(0xFFC62828),
    'Hills': Color(0xFF37474F),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AreaContactProvider>(
      builder: (context, prov, _) => Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Area Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, prov),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHero(),
          _buildRegionFilter(prov),
          if (prov.search.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('Results for "${prov.search}"',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => prov.setSearch(''),
                    child: const Text('Clear',
                        style: TextStyle(
                            color: Color(0xFF37474F), fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: prov.filtered.isEmpty && prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.filtered.isEmpty
                    ? _buildEmpty()
                    : prov.region != 'All'
                        ? _buildFlatList(prov.filtered)
                        : _buildGroupedList(prov),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800&h=300&fit=crop&auto=format',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFF37474F)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xE0263238), Color(0xC037474F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Assam District Network',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text('Area-Wise\nContact Persons',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2)),
                const SizedBox(height: 10),
                Row(children: [
                  _heroPill(Icons.map, '35 Districts'),
                  const SizedBox(width: 8),
                  _heroPill(Icons.groups, '6 Regions'),
                  const SizedBox(width: 8),
                  _heroPill(Icons.phone_in_talk, 'Direct Call'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildRegionFilter(AreaContactProvider prov) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _regions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = _regions[i];
          final sel = r == prov.region;
          final color =
              _regionColors[r] ?? const Color(0xFF37474F);
          return ChoiceChip(
            label: Text(r),
            selected: sel,
            onSelected: (_) => prov.setRegion(r),
            selectedColor: color,
            labelStyle: TextStyle(
              color: sel ? Colors.white : Colors.grey[700],
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildGroupedList(AreaContactProvider prov) {
    final grouped = prov.grouped;
    final regionOrder = [
      'Upper Assam',
      'Lower Assam',
      'Central Assam',
      'North Assam',
      'Barak Valley',
      'Hills',
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final region in regionOrder)
          if (grouped.containsKey(region)) ...[
            _buildRegionHeader(region, grouped[region]!.length),
            for (final c in grouped[region]!) _ContactCard(contact: c),
          ],
      ],
    );
  }

  Widget _buildFlatList(List<AreaContactModel> contacts) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: contacts.length,
      itemBuilder: (_, i) => _ContactCard(contact: contacts[i]),
    );
  }

  Widget _buildRegionHeader(String region, int count) {
    final color = _regionColors[region] ?? const Color(0xFF37474F);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(region,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count districts',
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No contacts found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, AreaContactProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) {
                prov.setSearch(v);
                Navigator.pop(context);
              },
              decoration: InputDecoration(
                hintText: 'Search district, name or designation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                fillColor: const Color(0xFFF0F0F0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final AreaContactModel contact;
  const _ContactCard({required this.contact});

  static const _regionColors = {
    'Upper Assam': Color(0xFF1565C0),
    'Lower Assam': Color(0xFF2E7D32),
    'Central Assam': Color(0xFF6A1B9A),
    'North Assam': Color(0xFF00695C),
    'Barak Valley': Color(0xFFC62828),
    'Hills': Color(0xFF37474F),
  };

  Color get _color =>
      _regionColors[contact.region] ?? const Color(0xFF37474F);

  String get _initials {
    final parts = contact.name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _color.withValues(alpha: 0.8),
                    _color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(contact.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(contact.district,
                            style: TextStyle(
                                fontSize: 10,
                                color: _color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(contact.designation,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text(contact.region,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11)),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        color: _color,
                        onTap: () => _showContactDialog(context, whatsapp: false),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _showContactDialog(context, whatsapp: true),
                      ),
                      const Spacer(),
                      Text(contact.phone,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              letterSpacing: 0.3)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext ctx, {required bool whatsapp}) {
    activityService.log(
      'call_contact',
      entityType: 'contact',
      entityId: contact.id,
      entityName: '${contact.name} - ${contact.district}',
      extra: {'phone': contact.phone, 'channel': whatsapp ? 'whatsapp' : 'call'},
    );
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(contact.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_color.withValues(alpha: 0.8), _color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(_initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Text(contact.designation,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text('${contact.district} · ${contact.region}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: _color, size: 16),
                  const SizedBox(width: 8),
                  Text(contact.phone,
                      style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final phone = whatsapp ? (contact.whatsapp ?? contact.phone) : contact.phone;
              final uri = whatsapp
                  ? Uri.parse('https://wa.me/91${phone.replaceAll(RegExp(r'[^\d]'), '')}')
                  : Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: whatsapp ? LaunchMode.externalApplication : LaunchMode.platformDefault);
              }
            },
            icon: Icon(whatsapp ? Icons.chat : Icons.phone, size: 16),
            label: Text(whatsapp ? 'WhatsApp' : 'Call Now'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
