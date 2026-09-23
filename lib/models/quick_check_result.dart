class QuickCheckResult {
  final String subjectName; // e.g. "Tomato", "Aloe Vera"
  final bool statusGood; // true = fresh/safe, false = spoiled/toxic
  final String statusLabel; // e.g. "Fresh", "Toxic to Pets"
  final int scorePercent; // 0-100 confidence/quality score
  final List<String> details; // observations
  final List<String> tips; // recommendations/storage/safety tips
  final bool isValidSubject; // false if image doesn't match expected subject type
  final String rawResponse;

  QuickCheckResult({
    required this.subjectName,
    required this.statusGood,
    required this.statusLabel,
    required this.scorePercent,
    required this.details,
    required this.tips,
    this.isValidSubject = true,
    this.rawResponse = '',
  });

  factory QuickCheckResult.fromJson(Map<String, dynamic> json) {
    return QuickCheckResult(
      subjectName: json['subject_name'] ?? 'Unknown',
      statusGood: json['status_good'] ?? true,
      statusLabel: json['status_label'] ?? '',
      scorePercent: (json['score_percent'] ?? 0) is int
          ? json['score_percent'] ?? 0
          : int.tryParse(json['score_percent'].toString()) ?? 0,
      details: List<String>.from(json['details'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      isValidSubject: json['is_valid_subject'] ?? true,
    );
  }

  factory QuickCheckResult.fallback(String rawText) {
    return QuickCheckResult(
      subjectName: 'Unknown',
      statusGood: false,
      statusLabel: 'Could not analyze',
      scorePercent: 0,
      details: [],
      tips: [],
      rawResponse: rawText,
    );
  }
}