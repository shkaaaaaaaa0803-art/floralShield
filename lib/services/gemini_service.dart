import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/diagnosis_model.dart';
import '../models/quick_check_result.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  late final GenerativeModel _quickCheckModel;
  // Fallback models: gemini-3.6/3.7/3.8-flash have documented, ongoing
  // capacity/overload issues (503 "high demand") reported widely on
  // Google's own developer forum as of Sept 2026. Flash-Lite isn't
  // implicated in those reports and normally has more headroom, so it's
  // used as a second attempt when the primary model is overloaded.
  late final GenerativeModel _modelFallback;
  late final GenerativeModel _chatModelFallback;
  late final GenerativeModel _quickCheckModelFallback;

  GeminiService() {
    final String? apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found. Check your .env file.');
    }

    // Strict JSON schema definition for universal plant validation & diagnosis
    final schema = Schema.object(
      properties: {
        'plant_name': Schema.string(
          description: "Name of plant, e.g. 'Lotus', 'Rose', 'Tomato', 'Monstera'. For non-plants, name the object.",
        ),
        'is_plant': Schema.boolean(
          description: "True if subject is any biological plant, flower, leaf, tree, or crop",
        ),
        'is_supported_crop': Schema.boolean(
          description: "Always true for ANY biological plant, flower, or leaf. Set false ONLY for non-plant objects.",
        ),
        'is_healthy': Schema.boolean(
          description: "True if plant shows no disease symptoms",
        ),
        'disease_name': Schema.string(
          description: "Name of plant disease, or 'None' if healthy",
        ),
        'confidence': Schema.string(
          description: "High, Medium, or Low",
        ),
        'confidence_percent': Schema.integer(
          description: "0 to 100 confidence score",
        ),
        'severity_percent': Schema.integer(
          description: "0 to 100 severity percentage (0 if healthy)",
        ),
        'symptoms': Schema.array(items: Schema.string()),
        'treatment': Schema.array(items: Schema.string()),
        'prevention': Schema.array(items: Schema.string()),
        'treatment_home': Schema.array(
          items: Schema.string(),
          description:
          "Treatment steps for a HOME GARDENER with a few potted or backyard plants: simple, low-cost, minimal/no chemical use (e.g. neem oil, insecticidal soap, pruning affected leaves, isolating the plant, hand-picking pests). Avoid naming industrial or restricted-use agricultural pesticides here.",
        ),
        'prevention_home': Schema.array(
          items: Schema.string(),
          description:
          "Prevention tips for a HOME GARDENER: watering habits, sunlight/placement, spacing, cleaning tools, basic organic care suited to a house or small yard.",
        ),
        'treatment_farmer': Schema.array(
          items: Schema.string(),
          description:
          "Treatment guidance for a FARMER managing this crop at field scale: relevant fungicide/pesticide/insecticide CLASSES or active-ingredient types (e.g. 'copper-based fungicide', 'systemic fungicide'), spray timing/interval guidance, and integrated pest management (IPM) practices. Do NOT include exact dosage amounts or mixing ratios -- the app has a separate dosage calculator for that. If healthy, give field-scale maintenance guidance instead.",
        ),
        'prevention_farmer': Schema.array(
          items: Schema.string(),
          description:
          "Field-scale prevention for a FARMER: crop rotation, resistant/tolerant varieties, sanitation of field debris, planting density/spacing, irrigation scheduling, and monitoring practices.",
        ),
        'affected_region': Schema.object(
          properties: {
            'x': Schema.number(),
            'y': Schema.number(),
            'radius': Schema.number(),
          },
        ),
      },
      requiredProperties: [
        'plant_name',
        'is_plant',
        'is_supported_crop',
        'is_healthy',
        'disease_name',
        'confidence',
        'confidence_percent',
        'severity_percent',
        'symptoms',
        'treatment',
        'prevention',
        'treatment_home',
        'prevention_home',
        'treatment_farmer',
        'prevention_farmer',
      ],
    );

    // Strict JSON schema for the Quick Check features (freshness, pet
    // toxicity, soil texture). This is intentionally separate from the
    // diagnosis `schema` above: it was previously sharing `_model`, whose
    // responseSchema only knows about plant_name/disease_name/etc, which
    // silently forced every quick-check answer into the wrong shape and
    // made QuickCheckResult.fromJson() fall back to 'Unknown'/empty values.
    final quickCheckSchema = Schema.object(
      properties: {
        'subject_name': Schema.string(
          description:
          "Name of the identified subject, e.g. 'Tomato', 'Aloe Vera', 'Sandy Loam'.",
        ),
        'is_valid_subject': Schema.boolean(
          description:
          "True if the image matches the expected subject type for this check (produce, plant, or soil). False otherwise.",
        ),
        'status_good': Schema.boolean(
          description:
          "True if fresh / safe for pets / suitable soil. False if spoiled / toxic / unsuitable.",
        ),
        'status_label': Schema.string(
          description:
          "Short status label, e.g. 'Fresh', 'Toxic to Pets', 'Sandy Loam'.",
        ),
        'score_percent': Schema.integer(
          description: "0 to 100 confidence/quality score.",
        ),
        'details': Schema.array(items: Schema.string()),
        'tips': Schema.array(items: Schema.string()),
        'stat_labels': Schema.array(
          items: Schema.string(),
          description:
          "Optional. Up to 3 short (1-3 word) labels for a compact stat row, e.g. ['Pesticide Residue', 'Surface Coating', 'Est. Shelf Life']. Leave empty if not applicable.",
        ),
        'stat_values': Schema.array(
          items: Schema.string(),
          description:
          "Optional. Up to 3 short (1-3 word) values matching stat_labels in the same order, e.g. ['Low', 'Natural wax', '3-4 days']. Leave empty if not applicable.",
        ),
        'pet_safe': Schema.boolean(
          description:
          "Optional, only meaningful for food/produce items. True if this specific food is safe for dogs/cats to eat in small amounts. False if it is a known pet toxin (e.g. grapes, raisins, onions, garlic, chocolate, avocado for birds, xylitol). Default true if not applicable.",
        ),
        'pet_safety_note': Schema.string(
          description:
          "Optional. A short, specific, factually accurate note about pet safety for this exact food item -- not a generic statement. Leave empty if not applicable.",
        ),
      },
      requiredProperties: [
        'subject_name',
        'is_valid_subject',
        'status_good',
        'status_label',
        'score_percent',
        'details',
        'tips',
      ],
    );

    _model = GenerativeModel(
      // gemini-1.5-flash was fully shut down; gemini-3.8-flash is the
      // current stable, vision-capable model Google recommends as of 2026.
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    _chatModel = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.6),
    );

    _quickCheckModel = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: quickCheckSchema,
      ),
    );

    _modelFallback = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    _chatModelFallback = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.6),
    );

    _quickCheckModelFallback = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: quickCheckSchema,
      ),
    );
  }

  /// Calls [model.generateContent], automatically retrying a few times
  /// with exponential backoff when the error looks transient (Google's
  /// servers returning 503 "UNAVAILABLE / high demand" or 429 rate limits).
  /// This is what actually protects the user from a single momentary
  /// server hiccup surfacing as a scan failure.
  Future<GenerateContentResponse> _generateWithRetry(
      GenerativeModel model,
      List<Content> content, {
        int maxAttempts = 3,
        GenerativeModel? fallbackModel,
      }) async {
    Object lastError = Exception('generateContent failed.');
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await model.generateContent(content);
      } catch (e) {
        lastError = e;
        final bool isTransient = _isTransientError(e);
        if (!isTransient) rethrow;
        if (attempt < maxAttempts) {
          // Backoff: ~800ms, 1.6s, 3.2s before the next attempt.
          await Future.delayed(Duration(milliseconds: 800 * (1 << (attempt - 1))));
        }
      }
    }

    // Primary model's retries are exhausted. If a fallback model was
    // given, try it once before giving up entirely -- this is what
    // actually helps when the primary model is congested Google-side
    // rather than down entirely.
    if (fallbackModel != null) {
      try {
        return await fallbackModel.generateContent(content);
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError;
  }

  bool _isTransientError(Object e) {
    final String msg = e.toString().toLowerCase();
    return msg.contains('503') ||
        msg.contains('unavailable') ||
        msg.contains('high demand') ||
        msg.contains('overloaded') ||
        msg.contains('429') ||
        msg.contains('resource_exhausted');
  }

  /// Turns a raw exception into a short, human-readable message instead of
  /// dumping a JSON error blob into the UI's "Symptoms" list.
  String _friendlyErrorMessage(Object e) {
    final String msg = e.toString().toLowerCase();
    if (msg.contains('503') || msg.contains('unavailable') || msg.contains('high demand') || msg.contains('overloaded')) {
      return "Gemini's servers are temporarily overloaded. We already retried automatically and tried a backup model — please wait a moment and scan again.";
    }
    if (msg.contains('429') || msg.contains('resource_exhausted')) {
      return "You've hit the current AI request rate limit. Please wait about a minute before scanning again.";
    }
    if (msg.contains('api key') || msg.contains('api_key_invalid') || msg.contains('401') || msg.contains('403') || msg.contains('permission')) {
      return 'There is a problem with the AI configuration (API key). Please contact support.';
    }
    if (msg.contains('socketexception') || msg.contains('network') || msg.contains('failed host lookup')) {
      return 'No internet connection could be reached. Check your connection and try again.';
    }
    return 'Could not complete image analysis due to a network or response issue.';
  }

  DiagnosisModel _getFallbackForError([String? errorMsg]) {
    return DiagnosisModel(
      plantName: 'Plant / Subject',
      isHealthy: false,
      diseaseName: 'Analysis Incomplete',
      confidence: 'Low',
      confidencePercent: 50,
      severityPercent: 10,
      symptoms: [
        errorMsg ?? 'Could not complete image analysis due to a network or response issue.'
      ],
      treatment: const ['Ensure your device has an active internet connection and try scanning again.'],
      prevention: const ['Take a clear, well-lit photo focusing directly on the plant surface.'],
      isPlant: true,
      isSupportedCrop: true,
      regionX: 0.5,
      regionY: 0.5,
      regionRadius: 0.2,
    );
  }

  Future<DiagnosisModel> analyzeImage(File imageFile, {List<File>? additionalImages}) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final bool hasMultiplePhotos = additionalImages != null && additionalImages.isNotEmpty;

      const String prompt = '''
You are an expert botanist and plant pathologist. 
Analyze the image to identify the plant species and diagnose its health status.

CRITICAL INSTRUCTIONS:
1. Identify the subject. If it is ANY biological plant, flower, leaf, tree, or crop, you MUST set 'is_plant': true and 'is_supported_crop': true.
2. Only if the subject is explicitly a non-plant object (e.g., shoe, electronics, car, furniture), set both to false.
3. Identify the species correctly (e.g., 'Lotus', 'Rose', 'Tomato', 'Monstera').
4. Provide a full diagnosis. If diseased, specify the disease name, symptoms, treatment, and prevention.
5. If healthy, set 'is_healthy': true, 'disease_name': 'None', and provide general care/maintenance tips in the symptoms, treatment, and prevention fields.
6. Never skip symptoms or treatment metrics for any biological plant subject.
7. Always fill treatment_home/prevention_home (simple, low/no-chemical advice for a home gardener) AND treatment_farmer/prevention_farmer (field-scale advice with relevant pesticide/fungicide classes for a farmer, but no exact dosage amounts) -- these are two different audiences reading the same diagnosis, so tailor each rather than repeating the general treatment/prevention text.
''';

      final List<Part> parts = <Part>[TextPart(prompt), DataPart('image/jpeg', imageBytes)];

      if (hasMultiplePhotos) {
        for (final File extraFile in additionalImages) {
          final Uint8List extraBytes = await extraFile.readAsBytes();
          parts.add(DataPart('image/jpeg', extraBytes));
        }
      }

      final List<Content> content = [Content.multi(parts)];
      final GenerateContentResponse response = await _generateWithRetry(_model, content, fallbackModel: _modelFallback);
      final String? text = response.text;

      if (text == null || text.isEmpty) {
        return _getFallbackForError('Empty response from AI server.');
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanText) as Map<String, dynamic>;
      return DiagnosisModel.fromJson(jsonData);
    } catch (e) {
      // ignore: avoid_print
      print('GEMINI ANALYSIS ERROR: $e');
      return _getFallbackForError(_friendlyErrorMessage(e));
    }
  }

  /// Translates an already-diagnosed result into another language
  Future<DiagnosisModel> translateDiagnosis(
      DiagnosisModel original,
      String languageName,
      ) async {
    const String promptPrefix = 'Translate the following plant diagnosis JSON into ';
    final String prompt = '''
$promptPrefix $languageName.
Keep the exact same JSON structure and field names. Only translate the
text values (plant_name, disease_name, confidence, symptoms, treatment,
prevention, treatment_home, prevention_home, treatment_farmer, prevention_farmer).
Keep is_healthy, confidence_percent, severity_percent, is_plant, and is_supported_crop
unchanged. Respond ONLY with valid JSON, no extra text.

\${jsonEncode(original.toJson())}
''';

    try {
      final GenerateContentResponse response = await _generateWithRetry(_model, [Content.text(prompt)], fallbackModel: _modelFallback);
      final String? text = response.text;

      if (text == null || text.isEmpty) {
        return original;
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanText) as Map<String, dynamic>;
      return DiagnosisModel.fromJson(jsonData);
    } catch (e) {
      return original;
    }
  }

  QuickCheckResult _getFreshnessFallback() {
    return QuickCheckResult(
      subjectName: 'Freshness Check Error',
      statusGood: false,
      statusLabel: 'Check Failed',
      scorePercent: 0,
      details: const ['Unable to analyze freshness at this moment. Please check internet connection.'],
      tips: const ['Try scanning the produce again with direct lighting.'],
      isValidSubject: false,
    );
  }

  QuickCheckResult _getPetToxicityFallback() {
    return QuickCheckResult(
      subjectName: 'Toxicity Check Error',
      statusGood: false,
      statusLabel: 'Check Failed',
      scorePercent: 0,
      details: const ['Unable to determine pet toxicity at this time.'],
      tips: const ['Consult a local vet or safety database if your pet consumed an unknown plant.'],
      isValidSubject: false,
    );
  }

  QuickCheckResult _getSoilTextureFallback() {
    return QuickCheckResult(
      subjectName: 'Soil Analysis Error',
      statusGood: false,
      statusLabel: 'Check Failed',
      scorePercent: 0,
      details: const ['Unable to analyze soil texture from this image.'],
      tips: const ['Take a clear close-up photo of soil in good lighting.'],
      isValidSubject: false,
    );
  }

  QuickCheckResult _getPlantIdFallback() {
    return QuickCheckResult(
      subjectName: 'Identification Error',
      statusGood: false,
      statusLabel: 'Check Failed',
      scorePercent: 0,
      details: const ['Unable to identify this plant at this time.'],
      tips: const ['Take a clear, well-lit photo showing the leaves and overall shape of the plant.'],
      isValidSubject: false,
    );
  }

  /// Analyzes a photo of produce (fruit/vegetable) for freshness.
  Future<QuickCheckResult> checkFreshness(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are a professional food quality inspector specializing in fresh produce (fruits and vegetables).
Look at the image and assess the freshness of the fruit or vegetable shown.
If the image does not show a fruit or vegetable, set is_valid_subject to false and identify what the image actually shows in subject_name instead.

Fill the fields as follows:
- status_label: a short freshness category, e.g. "Fresh", "Ripe", "Overripe", "Spoiled".
- score_percent: an overall freshness/quality score from 0-100 based on visible color, firmness, blemishes, and any mold or decay.
- stat_labels / stat_values: exactly 3 parallel short badges, in this order:
  1. label "Visual Pesticide Risk", value a short visual-estimate risk level such as "Low", "Moderate", or "High" (this is a visual estimate only, not a lab test -- base it on visible residue, spotting, or waxy build-up).
  2. label "Surface Coating", value a short description such as "Natural wax", "Light coating", "None visible", or "Heavy coating".
  3. label "Est. Shelf Life", value a short estimate such as "5-7 days", "2-3 days", or "Use today".
- details: 2-4 specific visual freshness observations (ripeness cues, blemishes, discoloration, firmness cues, any residue or coating noted). Do not invent exact lab measurements (like precise ppm numbers) -- keep observations visual and qualitative.
- tips: 3-4 ordered kitchen prep/wash steps appropriate for this specific item (e.g. produce with a waxy skin needs a different wash step than soft berries).
- pet_safe: true if this specific food is safe for dogs/cats to eat in small amounts; false if it is a known pet toxin (grapes/raisins, onions, garlic, chives, avocado, chocolate, xylitol, unripe tomatoes/potatoes (solanine), etc.). Be accurate and specific to the actual food identified -- do not default to true without checking.
- pet_safety_note: one short, specific, factually accurate sentence about pet safety for this exact food (not a generic "safe in moderation" statement copied for every food).
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _getFreshnessFallback();
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      return QuickCheckResult.fromJson(jsonDecode(cleanText) as Map<String, dynamic>);
    } catch (e) {
      return _getFreshnessFallback();
    }
  }

  /// Analyzes a photo of a plant for toxicity risk to common pets (dogs/cats).
  Future<QuickCheckResult> checkPetToxicity(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are a veterinary toxicology expert specializing in plant toxicity to common household pets (dogs and cats).
Look at the image and identify the plant shown, then assess whether it is toxic or safe for dogs and cats if chewed or ingested.
If the image does not show a plant, set is_valid_subject to false and identify what the image actually shows in subject_name instead.

Fill the fields as follows:
- status_label: a short label naming which pets are affected, e.g. "Toxic to Dogs & Cats", "Mildly Toxic to Cats", or "Safe for Pets".
- score_percent: your confidence (0-100) in this identification and toxicity assessment.
- details: if toxic, list the toxic principle (the specific compound, e.g. "Insoluble calcium oxalates") as the first item, then list the specific symptoms of poisoning a pet owner would observe (e.g. "Oral irritation and drooling", "Vomiting", "Difficulty swallowing"). If safe, list why it's considered non-toxic and any mild GI upset that can still occur from any plant material.
- tips: if toxic, list clear immediate action steps for a pet owner (e.g. "Remove your pet from the plant immediately", "Rinse mouth with water if safe to do so", "Contact your vet or an animal poison control hotline right away", "Bring a photo or sample of the plant to the vet"). If safe, list general safety notes (e.g. "Still monitor for mild stomach upset in sensitive pets", "Keep the plant out of reach as a general precaution").
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _getPetToxicityFallback();
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      return QuickCheckResult.fromJson(jsonDecode(cleanText) as Map<String, dynamic>);
    } catch (e) {
      return _getPetToxicityFallback();
    }
  }

  /// Analyzes a photo of soil to estimate its texture type and suitability.
  Future<QuickCheckResult> checkSoilTexture(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are an agricultural soil scientist. Look at the image showing soil.
Estimate the soil texture type (e.g. Sandy, Clay, Loamy, Silty, Sandy Loam) based on visible color, particle size, clumping, and moisture appearance.
If the image does not show soil at all, set is_valid_subject to false and identify what the image actually shows in subject_name instead.
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _getSoilTextureFallback();
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      return QuickCheckResult.fromJson(jsonDecode(cleanText) as Map<String, dynamic>);
    } catch (e) {
      return _getSoilTextureFallback();
    }
  }

  /// Identifies a plant species from a photo and gives basic care tips.
  Future<QuickCheckResult> identifyPlant(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are an expert botanist and houseplant specialist. Look at the image and identify the plant species shown (common name, and scientific name too if you can confidently determine it).
Set status_good to true if you can identify the plant with reasonable confidence, and false if it cannot be confidently identified.
Set status_label to a short one or two word category for the plant, e.g. "Succulent", "Houseplant", "Flowering Plant", "Herb", "Tree", or "Fern".
In details, list the distinguishing features you observed (leaf shape, growth habit) and, if identifiable, its typical native origin and whether it is generally toxic to common pets.
In tips, give brief care guidance: light needs, watering frequency, and a common care mistake to avoid.
If the image does not show a plant at all, set is_valid_subject to false and identify what the image actually shows in subject_name instead.
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _getPlantIdFallback();
      }

      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      return QuickCheckResult.fromJson(jsonDecode(cleanText) as Map<String, dynamic>);
    } catch (e) {
      return _getPlantIdFallback();
    }
  }

  /// Continues a multi-turn farming conversation
  Future<String> continueChat(List<Content> history) async {
    try {
      final GenerateContentResponse response = await _generateWithRetry(_chatModel, history, fallbackModel: _chatModelFallback);
      return response.text ?? 'Sorry, I could not understand that. Please try again.';
    } catch (e) {
      return 'Sorry, something went wrong. Please check your internet connection and try again.';
    }
  }

  /// Returns hidden priming turns establishing Krishi Saathi
  List<Content> chatPrimingTurns() {
    return [
      Content('user', [
        TextPart(
          'You are "Krishi Saathi", a friendly and knowledgeable farming assistant for Indian farmers. Answer questions about farming, plants, crops, pests, soil, and agriculture clearly and practically, in short, simple, warm sentences. If a question is unrelated to farming/agriculture, politely say you can only help with farming-related topics.',
        )
      ]),
      Content('model', [
        TextPart('Namaste! I am Krishi Saathi, your farming assistant. Ask me anything about your crops, plants, or farm.')
      ]),
    ];
  }
}