class LeadModel {
  final int id;
  final String title, projectType, location, status;
  final String? description, contact, deadline, postedBy;
  final double value;
  final bool isBuy;
  final List<String> images;
  final bool isAssignedToMe;

  const LeadModel({
    required this.id,
    required this.title,
    required this.projectType,
    required this.location,
    required this.status,
    this.description,
    this.contact,
    this.deadline,
    this.postedBy,
    required this.value,
    required this.isBuy,
    this.images = const [],
    this.isAssignedToMe = false,
  });

  factory LeadModel.fromJson(Map<String, dynamic> j) => LeadModel(
        id: j['id'],
        title: j['title'] ?? '',
        projectType: j['project_type'] ?? '',
        location: j['location'] ?? '',
        status: j['status'] ?? 'open',
        description: j['description'],
        contact: j['contact'],
        deadline: j['deadline'],
        postedBy: j['user']?['name'],
        value: (j['value'] as num).toDouble(),
        isBuy: j['is_buy'] == true || j['is_buy'] == 1,
        images: (j['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isAssignedToMe: j['is_assigned_to_me'] == true,
      );
}
