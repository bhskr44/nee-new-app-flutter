/// A user's request to switch to a different role, tracked through admin approval.
class RoleChangeRequestModel {
  final int id;
  final String currentRole;
  final String requestedRole;
  final String status; // pending | approved | rejected
  final String? adminNotes;
  final String createdAt;

  const RoleChangeRequestModel({
    required this.id,
    required this.currentRole,
    required this.requestedRole,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory RoleChangeRequestModel.fromJson(Map<String, dynamic> j) => RoleChangeRequestModel(
        id: j['id'],
        currentRole: j['current_role'] ?? '',
        requestedRole: j['requested_role'] ?? '',
        status: j['status'] ?? 'pending',
        adminNotes: j['admin_notes'],
        createdAt: j['created_at'] ?? '',
      );
}
