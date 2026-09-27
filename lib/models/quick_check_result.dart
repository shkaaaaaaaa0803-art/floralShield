class QuickCheckResult {
  final String subjectName; // e.g. "Tomato", "Aloe Vera"
  final bool statusGood; // true = fresh/safe, false = spoiled/toxic
  final String statusLabel; // e.g. "Fresh", "Toxic to Pets"
  final int scorePercent; // 0-100 confidence/quality score
  final List<String> details; // observations
  final List<String> tips; // recommendations/storage/safety tips
  final bool isValidSubject; // false if image doesn't match expected subject type
  final String rawResponse;

  // Optional short "badge" stats for a compact stat row (e.g. Freshness
  // Scanner's Pesticide/Coating/Shelf-life row). Parallel lists -- item i
  // of statLabels pairs with item i of statValues. Empty for modes that
  // don't use this (soil texture, plant ID, pet toxicity).
  final List<String> statLabels;
  final List<String> statValues;

  // Whether the specific food item itself (not residue/wax on it) is safe
  // for pets to eat, plus a real explanation. Only meaningfully used by
  // the Freshness Scanner -- some produce (grapes, onions, garlic, etc.)
  // is genuinely toxic to dogs/cats regardless of freshness.
  final bool petSafe;
  final String petSafetyNote;

  QuickCheckResult({
    required this.subjectName,
    required this.statusGood,
    required this.statusLabel,
    required this.scorePercent,
    required this.details,
    required this.tips,
    this.isValidSubject = true,
    this.rawResponse = '',
    this.statLabels = const [],
    this.statValues = const [],
    this.petSafe = true,
    this.petSafetyNote = '',
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
      statLabels: List<String>.from(json['stat_labels'] ?? []),
      statValues: List<String>.from(json['stat_values'] ?? []),
      petSafe: json['pet_safe'] ?? true,
      petSafetyNote: json['pet_safety_note'] ?? '',
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