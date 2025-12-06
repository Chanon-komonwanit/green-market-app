// lib/services/ai_eco_analysis_service.dart
// 🤖 AI-Powered Eco Score Analysis Service
// ใช้ Google Gemini AI (Free API) วิเคราะห์ความเป็น Eco ของสินค้า

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_settings.dart';

/// ผลการวิเคราะห์จาก AI
class EcoAnalysisResult {
  final int aiEcoScore; // 0-100
  final String aiReasoning; // เหตุผลจาก AI
  final List<String> aiSuggestions; // คำแนะนำปรับปรุง
  final List<String> detectedMaterials; // วัสดุที่ AI ตรวจพบ
  final Map<String, double> scoreBreakdown; // คะแนนแยกตามหมวด
  final String ecoLevel; // standard, good, excellent, champion
  final bool isVerified; // ผ่านการตรวจสอบหรือยัง
  final String confidence; // ความมั่นใจของ AI (high, medium, low)

  EcoAnalysisResult({
    required this.aiEcoScore,
    required this.aiReasoning,
    required this.aiSuggestions,
    required this.detectedMaterials,
    required this.scoreBreakdown,
    required this.ecoLevel,
    this.isVerified = false,
    this.confidence = 'medium',
  });

  Map<String, dynamic> toMap() {
    return {
      'aiEcoScore': aiEcoScore,
      'aiReasoning': aiReasoning,
      'aiSuggestions': aiSuggestions,
      'detectedMaterials': detectedMaterials,
      'scoreBreakdown': scoreBreakdown,
      'ecoLevel': ecoLevel,
      'isVerified': isVerified,
      'confidence': confidence,
      'analyzedAt': FieldValue.serverTimestamp(),
    };
  }

  factory EcoAnalysisResult.fromMap(Map<String, dynamic> map) {
    return EcoAnalysisResult(
      aiEcoScore: map['aiEcoScore'] ?? 0,
      aiReasoning: map['aiReasoning'] ?? '',
      aiSuggestions: List<String>.from(map['aiSuggestions'] ?? []),
      detectedMaterials: List<String>.from(map['detectedMaterials'] ?? []),
      scoreBreakdown: Map<String, double>.from(map['scoreBreakdown'] ?? {}),
      ecoLevel: map['ecoLevel'] ?? 'standard',
      isVerified: map['isVerified'] ?? false,
      confidence: map['confidence'] ?? 'medium',
    );
  }
}

/// ข้อมูลสินค้าสำหรับการวิเคราะห์
class ProductEcoData {
  final String productName;
  final String description;
  final int sellerClaimedScore; // คะแนนที่ผู้ขายบอก
  final String sellerJustification; // เหตุผลที่ผู้ขายบอก
  final List<String> materials; // วัสดุที่ใช้
  final List<String> certificates; // ใบรับรอง (ถ้ามี)
  final String manufacturingProcess; // กระบวนการผลิต
  final String packagingType; // ประเภทบรรจุภัณฑ์
  final String wasteManagement; // การจัดการขยะ
  final String category; // หมวดหมู่สินค้า

  ProductEcoData({
    required this.productName,
    required this.description,
    required this.sellerClaimedScore,
    required this.sellerJustification,
    required this.materials,
    this.certificates = const [],
    this.manufacturingProcess = '',
    this.packagingType = '',
    this.wasteManagement = '',
    this.category = '',
  });
}

class AIEcoAnalysisService {
  // 🔑 Gemini API Key (Free tier: 60 requests/minute)
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// วิเคราะห์ความเป็น Eco ของสินค้าด้วย AI
  Future<EcoAnalysisResult> analyzeProduct(ProductEcoData data) async {
    try {
      // 🔍 ตรวจสอบว่า AI เปิดใช้งานหรือไม่
      final settings = await getAISettings();

      if (!settings.canUseAI()) {
        print('⚠️ AI ถูกปิดใช้งานหรือเกิน daily limit');
        return _fallbackAnalysis(data);
      }

      // 📊 เพิ่ม usage count
      await _incrementUsage();

      // สร้าง prompt สำหรับ AI
      final String prompt = _buildAnalysisPrompt(data);

      // เรียก Gemini AI (ใช้ API key จาก settings)
      final response = await _callGeminiAPI(prompt, settings.apiKey);

      // แปลงผลลัพธ์จาก AI
      final result = _parseAIResponse(response, data);

      // บันทึกผลการวิเคราะห์เพื่อ ML Learning
      await _saveLearningData(data, result);

      return result;
    } catch (e) {
      print('Error in AI analysis: $e');
      // ถ้า AI ล้ม fallback เป็นการคำนวณแบบธรรมดา
      return _fallbackAnalysis(data);
    }
  }

  /// สร้าง prompt สำหรับ AI
  String _buildAnalysisPrompt(ProductEcoData data) {
    return '''
You are an expert environmental sustainability analyst for Green Market, an eco-friendly marketplace.

Analyze this product and provide a detailed eco-friendliness assessment:

**Product Information:**
- Name: ${data.productName}
- Description: ${data.description}
- Category: ${data.category}
- Materials: ${data.materials.join(', ')}
- Manufacturing Process: ${data.manufacturingProcess}
- Packaging: ${data.packagingType}
- Waste Management: ${data.wasteManagement}
- Certificates: ${data.certificates.join(', ')}

**Seller's Claim:**
- Eco Score: ${data.sellerClaimedScore}/100
- Justification: ${data.sellerJustification}

**Your Task:**
Provide a JSON response with:
1. "aiEcoScore": Your assessed score (0-100)
2. "aiReasoning": Detailed explanation in Thai (2-3 paragraphs)
3. "aiSuggestions": Array of 3-5 improvement suggestions in Thai
4. "detectedMaterials": Array of detected eco-friendly materials
5. "scoreBreakdown": Object with scores for:
   - materials (0-25): Quality of materials used
   - manufacturing (0-25): Production process sustainability
   - packaging (0-20): Packaging eco-friendliness
   - wasteManagement (0-15): End-of-life handling
   - certificates (0-15): Valid certifications
6. "confidence": "high", "medium", or "low"
7. "comparisonWithSeller": Comparison with seller's claim

Focus on:
- Material sustainability (recyclable, biodegradable, renewable)
- Manufacturing carbon footprint
- Packaging waste
- Product lifecycle
- Certifications validity

Be thorough but fair. Output ONLY valid JSON, no markdown.
''';
  }

  /// เรียก Gemini AI API
  Future<String> _callGeminiAPI(String prompt, String apiKey) async {
    // ใช้ API key จาก settings แทน hardcoded
    final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _geminiApiKey;

    final response = await http.post(
      Uri.parse('$_geminiApiUrl?key=$effectiveApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  /// แปลงผลลัพธ์จาก AI
  EcoAnalysisResult _parseAIResponse(String aiResponse, ProductEcoData data) {
    try {
      // ลบ markdown code blocks ถ้ามี
      String cleanedResponse =
          aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic> parsed = jsonDecode(cleanedResponse);

      final scoreBreakdown = Map<String, double>.from(
        parsed['scoreBreakdown']?.map((k, v) => MapEntry(k, v.toDouble())) ??
            {},
      );

      final int aiScore = parsed['aiEcoScore'] ?? data.sellerClaimedScore;
      final String ecoLevel = _determineEcoLevel(aiScore);

      return EcoAnalysisResult(
        aiEcoScore: aiScore,
        aiReasoning: parsed['aiReasoning'] ?? 'ไม่สามารถวิเคราะห์ได้',
        aiSuggestions: List<String>.from(parsed['aiSuggestions'] ?? []),
        detectedMaterials: List<String>.from(parsed['detectedMaterials'] ?? []),
        scoreBreakdown: scoreBreakdown,
        ecoLevel: ecoLevel,
        confidence: parsed['confidence'] ?? 'medium',
        isVerified: false,
      );
    } catch (e) {
      print('Error parsing AI response: $e');
      return _fallbackAnalysis(data);
    }
  }

  /// กำหนดระดับ Eco Level
  String _determineEcoLevel(int score) {
    if (score >= 90) return 'champion';
    if (score >= 75) return 'excellent';
    if (score >= 60) return 'good';
    return 'standard';
  }

  /// Fallback analysis ถ้า AI ไม่ทำงาน
  EcoAnalysisResult _fallbackAnalysis(ProductEcoData data) {
    int calculatedScore = _calculateBasicScore(data);

    return EcoAnalysisResult(
      aiEcoScore: calculatedScore,
      aiReasoning:
          'การวิเคราะห์เบื้องต้นจากระบบ: สินค้านี้มีคุณสมบัติที่เป็นมิตรกับสิ่งแวดล้อมในระดับปานกลาง โดยพิจารณาจากวัสดุที่ใช้และคำอธิบายของผู้ขาย',
      aiSuggestions: [
        'เพิ่มรายละเอียดเกี่ยวกับวัสดุที่ใช้',
        'ระบุแหล่งที่มาของวัตถุดิบ',
        'แนบใบรับรองมาตรฐาน (ถ้ามี)',
      ],
      detectedMaterials: data.materials,
      scoreBreakdown: {
        'materials': 15.0,
        'manufacturing': 15.0,
        'packaging': 10.0,
        'wasteManagement': 8.0,
        'certificates': 0.0,
      },
      ecoLevel: _determineEcoLevel(calculatedScore),
      confidence: 'low',
    );
  }

  /// คำนวณคะแนนแบบพื้นฐาน
  int _calculateBasicScore(ProductEcoData data) {
    int score = 0;

    // วัสดุ (max 30)
    final ecoMaterials = [
      'bamboo',
      'organic',
      'recycled',
      'biodegradable',
      'natural',
      'ไม้ไผ่',
      'ออร์แกนิค',
      'รีไซเคิล',
      'ย่อยสลาย',
      'ธรรมชาติ'
    ];
    int materialScore = 0;
    for (var material in data.materials) {
      if (ecoMaterials
          .any((eco) => material.toLowerCase().contains(eco.toLowerCase()))) {
        materialScore += 10;
      }
    }
    score += materialScore.clamp(0, 30);

    // คำอธิบาย (max 20)
    if (data.sellerJustification.length > 100) score += 15;
    if (data.description.length > 200) score += 5;

    // กระบวนการผลิต (max 20)
    if (data.manufacturingProcess.isNotEmpty) score += 15;

    // บรรจุภัณฑ์ (max 15)
    if (data.packagingType.toLowerCase().contains('eco') ||
        data.packagingType.toLowerCase().contains('recycle')) {
      score += 15;
    }

    // ใบรับรอง (max 15)
    score += (data.certificates.length * 5).clamp(0, 15);

    return score.clamp(0, 100);
  }

  /// บันทึกข้อมูลสำหรับ Machine Learning
  Future<void> _saveLearningData(
      ProductEcoData data, EcoAnalysisResult result) async {
    try {
      await _firestore.collection('ai_learning_data').add({
        'productName': data.productName,
        'category': data.category,
        'sellerClaimedScore': data.sellerClaimedScore,
        'aiEcoScore': result.aiEcoScore,
        'scoreDifference': (result.aiEcoScore - data.sellerClaimedScore).abs(),
        'materials': data.materials,
        'confidence': result.confidence,
        'timestamp': FieldValue.serverTimestamp(),
        'needsReview': (result.aiEcoScore - data.sellerClaimedScore).abs() > 20,
      });
    } catch (e) {
      print('Error saving learning data: $e');
    }
  }

  /// ปรับปรุง AI Model จาก Admin Feedback
  Future<void> learnFromAdminFeedback({
    required String productId,
    required int adminApprovedScore,
    required int aiPredictedScore,
    required List<String> adminComments,
  }) async {
    try {
      await _firestore.collection('ai_feedback_training').add({
        'productId': productId,
        'adminApprovedScore': adminApprovedScore,
        'aiPredictedScore': aiPredictedScore,
        'scoreDifference': (adminApprovedScore - aiPredictedScore).abs(),
        'adminComments': adminComments,
        'timestamp': FieldValue.serverTimestamp(),
        'isProcessed': false,
      });

      // Update AI accuracy statistics
      await _updateAIAccuracy(adminApprovedScore, aiPredictedScore);
    } catch (e) {
      print('Error saving admin feedback: $e');
    }
  }

  /// อัพเดทความแม่นยำของ AI
  Future<void> _updateAIAccuracy(int adminScore, int aiScore) async {
    final doc = _firestore.collection('ai_statistics').doc('accuracy');
    await doc.set({
      'totalAnalysis': FieldValue.increment(1),
      'totalAccuracyPoints':
          FieldValue.increment(100 - (adminScore - aiScore).abs()),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ดึงสถิติความแม่นยำของ AI
  Future<Map<String, dynamic>> getAIAccuracyStats() async {
    try {
      final doc =
          await _firestore.collection('ai_statistics').doc('accuracy').get();
      if (doc.exists) {
        final data = doc.data()!;
        final total = data['totalAnalysis'] ?? 0;
        final points = data['totalAccuracyPoints'] ?? 0;
        final accuracy = total > 0 ? (points / total).toDouble() : 0.0;
        return {
          'totalAnalysis': total,
          'accuracy': accuracy,
          'lastUpdated': data['lastUpdated'],
        };
      }
    } catch (e) {
      print('Error getting AI accuracy stats: $e');
    }
    return {'totalAnalysis': 0, 'accuracy': 0.0};
  }

  // ================== AI SETTINGS MANAGEMENT ==================

  /// ดึงการตั้งค่า AI
  Future<AISettings> getAISettings() async {
    try {
      final doc =
          await _firestore.collection('app_settings').doc('ai_config').get();

      if (doc.exists && doc.data() != null) {
        final settings = AISettings.fromMap(doc.data()!);

        // ตรวจสอบว่าต้อง reset usage หรือไม่
        final now = DateTime.now();
        final lastReset = settings.lastResetDate;
        final today = DateTime(now.year, now.month, now.day);
        final resetDate =
            DateTime(lastReset.year, lastReset.month, lastReset.day);

        if (today.isAfter(resetDate)) {
          // Reset usage เพราะเปลี่ยนวันแล้ว
          final resetSettings = settings.copyWith(
            currentUsage: 0,
            lastResetDate: now,
          );
          await updateAISettings(resetSettings);
          return resetSettings;
        }

        return settings;
      } else {
        // สร้างค่าเริ่มต้น
        final defaultSettings = AISettings.defaultSettings();
        await _firestore
            .collection('app_settings')
            .doc('ai_config')
            .set(defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting AI settings: $e');
      return AISettings.defaultSettings();
    }
  }

  /// อัพเดทการตั้งค่า AI
  Future<void> updateAISettings(AISettings settings) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('ai_config')
          .set(settings.toMap(), SetOptions(merge: true));
      print('✅ AI Settings updated successfully');
    } catch (e) {
      print('❌ Error updating AI settings: $e');
      rethrow;
    }
  }

  /// เปิด/ปิด AI
  Future<void> toggleAI(bool enabled, String adminId) async {
    try {
      final settings = await getAISettings();
      final updatedSettings = settings.copyWith(
        aiEnabled: enabled,
        updatedAt: DateTime.now(),
        updatedBy: adminId,
      );
      await updateAISettings(updatedSettings);
    } catch (e) {
      print('Error toggling AI: $e');
      rethrow;
    }
  }

  /// เพิ่ม usage count
  Future<void> _incrementUsage() async {
    try {
      await _firestore.collection('app_settings').doc('ai_config').update({
        'currentUsage': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing usage: $e');
    }
  }

  /// ดึงสถิติ usage วันนี้
  Future<Map<String, dynamic>> getTodayUsageStats() async {
    try {
      final settings = await getAISettings();
      return {
        'currentUsage': settings.currentUsage,
        'dailyLimit': settings.dailyLimit,
        'remainingUsage': settings.remainingUsage,
        'usagePercentage': settings.usagePercentage,
        'canUseAI': settings.canUseAI(),
        'aiEnabled': settings.aiEnabled,
      };
    } catch (e) {
      print('Error getting usage stats: $e');
      return {
        'currentUsage': 0,
        'dailyLimit': 1500,
        'remainingUsage': 1500,
        'usagePercentage': 0.0,
        'canUseAI': false,
        'aiEnabled': false,
      };
    }
  }
}
