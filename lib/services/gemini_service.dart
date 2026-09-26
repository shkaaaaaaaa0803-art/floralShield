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

    // Strict JSON schema for the Quick Check features
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
          await Future.delayed(Duration(milliseconds: 800 * (1 << (attempt - 1))));
        }
      }
    }

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

  String _friendlyErrorMessage(Object e) {
    final String msg = e.toString().toLowerCase();
    if (msg.contains('503') || msg.contains('unavailable') || msg.contains('high demand') || msg.contains('overloaded')) {
      return "AI servers are overloaded. We tried a backup model — please wait a moment and scan again.";
    }
    if (msg.contains('429') || msg.contains('resource_exhausted')) {
      return "Request rate limit hit. Please wait a minute before scanning again.";
    }
    if (msg.contains('api key') || msg.contains('401') || msg.contains('403')) {
      return 'AI configuration error (API key). Please contact support.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Could not complete analysis due to a network or response issue.';
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
        errorMsg ?? 'Analysis issue.'
      ],
      treatment: const ['Ensure internet and try again.'],
      prevention: const ['Take a clear photo.'],
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
7. Always fill treatment_home/prevention_home (simple advice for a home gardener) AND treatment_farmer/prevention_farmer (field-scale advice for a farmer).
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
      return _getFallbackForError(_friendlyErrorMessage(e));
    }
  }

  Future<DiagnosisModel> translateDiagnosis(
      DiagnosisModel original,
      String languageName,
      ) async {
    final String prompt = '''
Translate the following plant diagnosis JSON into $languageName.
Keep the exact same JSON structure. Only translate text values.
Keep boolean and numeric values unchanged. 
Respond ONLY with valid JSON.

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

  Future<QuickCheckResult> checkFreshness(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are a professional food quality inspector specializing in fresh produce (fruits and vegetables).
Look at the image and assess the freshness of the fruit or vegetable shown.
If the image does not show a fruit or vegetable, set is_valid_subject to false and identify what the image actually shows in subject_name instead.
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return QuickCheckResult.fallback('Empty response');
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
      return QuickCheckResult.fallback(e.toString());
    }
  }

  Future<QuickCheckResult> checkPetToxicity(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are a veterinary toxicology expert specializing in plant toxicity to common household pets (dogs and cats).
Look at the image and identify the plant shown, then assess whether it is toxic or safe for dogs and cats if chewed or ingested.
If the image does not show a plant, set is_valid_subject to false and identify what the image actually shows in subject_name instead.
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return QuickCheckResult.fallback('Empty response');
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
      return QuickCheckResult.fallback(e.toString());
    }
  }

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
        return QuickCheckResult.fallback('Empty response');
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
      return QuickCheckResult.fallback(e.toString());
    }
  }

  Future<QuickCheckResult> identifyPlant(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      const String prompt = '''
You are an expert botanist and houseplant specialist. Look at the image and identify the plant species shown.
If the image does not show a plant at all, set is_valid_subject to false and identify what the image actually shows in subject_name instead.
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _generateWithRetry(_quickCheckModel, content, fallbackModel: _quickCheckModelFallback);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return QuickCheckResult.fallback('Empty response');
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
      return QuickCheckResult.fallback(e.toString());
    }
  }

  Future<String> continueChat(List<Content> history) async {
    try {
      final GenerateContentResponse response = await _generateWithRetry(_chatModel, history, fallbackModel: _chatModelFallback);
      return response.text ?? 'Sorry, I could not understand that.';
    } catch (e) {
      return 'Sorry, something went wrong.';
    }
  }

  List<Content> chatPrimingTurns() {
    return [
      Content('user', [
        TextPart(
          'You are "Krishi Saathi", a friendly farming assistant for Indian farmers. Answer questions clearly.',
        )
      ]),
      Content('model', [
        TextPart('Namaste! I am Krishi Saathi.')
      ]),
    ];
  }
}