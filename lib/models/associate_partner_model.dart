/// An Area Manager working in the Associate Partner's district, with basic activity stats.
class StaffAreaManager {
  final int id;
  final String name;
  final String? phone;
  final int totalCalls;
  final int hotLeads;
  final String? lastActivity;

  const StaffAreaManager({
    required this.id,
    required this.name,
    this.phone,
    required this.totalCalls,
    required this.hotLeads,
    this.lastActivity,
  });

  factory StaffAreaManager.fromJson(Map<String, dynamic> j) => StaffAreaManager(
        id: j['id'],
        name: j['name'] ?? '',
        phone: j['phone'],
        totalCalls: j['total_calls'] ?? 0,
        hotLeads: j['hot_leads'] ?? 0,
        lastActivity: j['last_activity'],
      );
}

/// A Lead Manager working in the Associate Partner's district, with visit stats.
class StaffLeadManager {
  final int id;
  final String name;
  final String? phone;
  final int totalVisits;
  final int completedVisits;
  final List<String> districts;

  const StaffLeadManager({
    required this.id,
    required this.name,
    this.phone,
    required this.totalVisits,
    required this.completedVisits,
    required this.districts,
  });

  factory StaffLeadManager.fromJson(Map<String, dynamic> j) => StaffLeadManager(
        id: j['id'],
        name: j['name'] ?? '',
        phone: j['phone'],
        totalVisits: j['total_visits'] ?? 0,
        completedVisits: j['completed_visits'] ?? 0,
        districts: (j['districts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}
