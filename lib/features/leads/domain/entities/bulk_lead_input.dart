class BulkLeadInput {
  final String fullName;
  final String phone;
  final String region;

  const BulkLeadInput({
    required this.fullName,
    required this.phone,
    this.region = '',
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        'source': 'manual',
        if (region.isNotEmpty) 'region': region,
      };
}
