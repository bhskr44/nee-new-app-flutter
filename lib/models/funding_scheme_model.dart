class FundingSchemeModel {
  final int id;
  final String name, provider, type, description;
  final double minAmount, maxAmount, interestRate;
  final String? tenure, eligibility, documents, applyUrl, contactNumber;

  const FundingSchemeModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.interestRate,
    this.tenure,
    this.eligibility,
    this.documents,
    this.applyUrl,
    this.contactNumber,
  });

  factory FundingSchemeModel.fromJson(Map<String, dynamic> j) => FundingSchemeModel(
        id: j['id'],
        name: j['name'] ?? '',
        provider: j['provider'] ?? '',
        type: j['type'] ?? '',
        description: j['description'] ?? '',
        minAmount: (j['min_amount'] as num).toDouble(),
        maxAmount: (j['max_amount'] as num).toDouble(),
        interestRate: (j['interest_rate'] as num).toDouble(),
        tenure: j['tenure'],
        eligibility: j['eligibility'],
        documents: j['documents'],
        applyUrl: j['apply_url'],
        contactNumber: j['contact_number'],
      );
}
