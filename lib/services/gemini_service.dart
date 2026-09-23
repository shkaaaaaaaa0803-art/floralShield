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
      ],
    );

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    _chatModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.6),
    );
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
''';

      final List<Part> parts = <Part>[TextPart(prompt), DataPart('image/jpeg', imageBytes)];

      if (hasMultiplePhotos) {
        for (final File extraFile in additionalImages) {
          final Uint8List extraBytes = await extraFile.readAsBytes();
          parts.add(DataPart('image/jpeg', extraBytes));
        }
      }

      final List<Content> content = [Content.multi(parts)];
      final GenerateContentResponse response = await _model.generateContent(content);
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
      return _getFallbackForError(e.toString());
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
prevention). Keep is_healthy, confidence_percent, severity_percent, is_plant, and is_supported_crop
unchanged. Respond ONLY with valid JSON, no extra text.

\${jsonEncode(original.toJson())}
''';

    try {
      final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
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

  /// Analyzes a photo of produce (fruit/vegetable) for freshness.
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

      final GenerateContentResponse response = await _model.generateContent(content);
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
''';

      final List<Content> content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];

      final GenerateContentResponse response = await _model.generateContent(content);
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

      final GenerateContentResponse response = await _model.generateContent(content);
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

  /// Continues a multi-turn farming conversation
  Future<String> continueChat(List<Content> history) async {
    try {
      final GenerateContentResponse response = await _chatModel.generateContent(history);
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
