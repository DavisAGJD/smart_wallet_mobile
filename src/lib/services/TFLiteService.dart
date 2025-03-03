import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;
  // Longitud de secuencia que espera el modelo (32, según el entrenamiento)
  final int maxSeqLen = 32;

  // Lista de categorías (10 clases, en el mismo orden que se entrenó)
  final List<String> categories = [
    "Alimentación",
    "Transporte",
    "Entretenimiento",
    "Educación",
    "Salud",
    "Hogar",
    "Ropa",
    "Tecnología",
    "Viajes",
    "Otros"
  ];

  // Vocabulario del modelo BERT (mapa token -> índice)
  late Map<String, int> vocabulary;

  // Variables para los tokens especiales y configuración del tokenizador
  late bool doLowerCase;
  late String clsToken;
  late String sepToken;
  late String unkToken;
  late String padToken;
  late String maskToken;

  /// Carga el modelo TFLite, el vocabulario y la configuración de tokenización.
  Future<void> loadModel() async {
    try {
      await _loadVocabulary();
      await _loadSpecialTokens(); // Carga de special_tokens_map.json
      await _loadTokenizerConfig(); // Carga de tokenizer_config.json
      // Asegúrate de que la ruta coincida con el nombre del modelo generado
      _interpreter = await Interpreter.fromAsset(
        'assets/models/expense_classifier_seq.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      _interpreter.allocateTensors();
      _debugModelInfo();
      print('✅ Modelo TFLite cargado exitosamente');
    } catch (e) {
      print('❌ Error al cargar modelo: $e');
      rethrow;
    }
  }

  /// Carga el vocabulario desde el asset "assets/labels/vocab.txt".
  Future<void> _loadVocabulary() async {
    try {
      final vocabString =
          await rootBundle.loadString('assets/labels/vocab.txt');
      final lines = vocabString.split('\n');
      vocabulary = {};
      for (var i = 0; i < lines.length; i++) {
        String token = lines[i].trim();
        if (token.isNotEmpty) {
          vocabulary[token] = i;
        }
      }
      print('📚 Vocabulario cargado (${vocabulary.length} tokens)');
    } catch (e) {
      print('❌ Error cargando vocabulario: $e');
      rethrow;
    }
  }

  /// Carga los tokens especiales desde "assets/labels/special_tokens_map.json".
  Future<void> _loadSpecialTokens() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/labels/special_tokens_map.json');
      Map<String, dynamic> specialTokens = jsonDecode(jsonString);
      unkToken = specialTokens["unk_token"];
      sepToken = specialTokens["sep_token"];
      padToken = specialTokens["pad_token"];
      clsToken = specialTokens["cls_token"];
      maskToken = specialTokens["mask_token"];
      print('🔍 Special tokens cargados: $specialTokens');
    } catch (e) {
      print('❌ Error cargando special tokens: $e');
      rethrow;
    }
  }

  /// Carga la configuración del tokenizador desde "assets/labels/tokenizer_config.json".
  Future<void> _loadTokenizerConfig() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/labels/tokenizer_config.json');
      Map<String, dynamic> config = jsonDecode(jsonString);
      doLowerCase = config["do_lower_case"] ?? false;
      print('🔍 Configuración del tokenizador cargada: $config');
    } catch (e) {
      print('❌ Error cargando configuración del tokenizador: $e');
      rethrow;
    }
  }

  /// Normaliza el texto reemplazando "$" seguido de dígitos por "número pesos".
  String _normalizeText(String text) {
    String normalized = text.replaceAllMapped(
      RegExp(r'\$\s*(\d+(?:[.,]\d+)?)'),
      (match) {
        String number = match.group(1)!.replaceAll(',', '.');
        return '$number pesos';
      },
    );
    print('🔍 Normalized Text: $normalized');
    return normalized;
  }

  /// Tokenización básica que soporta Unicode.
  List<String> _basicTokenizer(String text) {
    RegExp exp = RegExp(r"([\p{L}\p{N}]+|[^\p{L}\p{N}\s])", unicode: true);
    List<String> tokens = exp.allMatches(text).map((m) => m.group(0)!).toList();
    print('🔍 Basic Tokens (Unicode): $tokens');
    return tokens;
  }

  /// Tokeniza una palabra usando el algoritmo WordPiece.
  List<String> _wordPieceTokenize(String word) {
    List<String> tokens = [];
    int start = 0;
    while (start < word.length) {
      int end = word.length;
      bool foundMatch = false;
      String subToken = '';
      while (start < end) {
        String substr = word.substring(start, end);
        if (start > 0) {
          substr = '##' + substr;
        }
        if (vocabulary.containsKey(substr)) {
          subToken = substr;
          foundMatch = true;
          break;
        }
        end--;
      }
      if (!foundMatch) {
        tokens.add(unkToken);
        print(
            '⚠️ WordPiece: No se encontró coincidencia para "$word" a partir de la posición $start, asignando $unkToken');
        break;
      }
      tokens.add(subToken);
      start = end;
    }
    print('🔍 WordPiece tokens for "$word": $tokens');
    return tokens;
  }

  /// Tokeniza el texto para BERT y agrega tokens especiales.
  List<int> _tokenizeBERT(String text) {
    if (doLowerCase) {
      text = text.toLowerCase();
    }
    List<String> basicTokens = _basicTokenizer(text);
    List<String> tokens = [];
    tokens.add(clsToken);
    for (String token in basicTokens) {
      tokens.addAll(_wordPieceTokenize(token));
    }
    tokens.add(sepToken);
    print('🔍 Full token sequence: $tokens');
    List<int> tokenIds =
        tokens.map((t) => vocabulary[t] ?? vocabulary[unkToken]!).toList();
    print('🔍 Token IDs antes de padding/truncation: $tokenIds');
    if (tokenIds.length > maxSeqLen) {
      tokenIds = tokenIds.sublist(0, maxSeqLen);
      print('🔍 Token IDs truncados a maxSeqLen: $tokenIds');
    } else {
      while (tokenIds.length < maxSeqLen) {
        tokenIds.add(vocabulary[padToken] ?? 0);
      }
      print('🔍 Token IDs con padding: $tokenIds');
    }
    return tokenIds;
  }

  /// Extrae el primer número que se encuentre en el texto.
  double _extractAmount(String text) {
    RegExp regex = RegExp(r'(\d+(?:[.,]\d+)?)');
    Match? match = regex.firstMatch(text);
    if (match != null) {
      String rawAmount = match.group(0)!;
      double amount = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
      print('🔍 Extracted amount: $amount');
      return amount;
    }
    print('🔍 No se encontró cantidad en el texto.');
    return 0.0;
  }

  /// Función softmax para convertir logits en probabilidades.
  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(math.max);
    List<double> expValues =
        logits.map((logit) => exp(logit - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    List<double> probabilities = expValues.map((e) => e / sumExp).toList();
    print('🔍 Logits: $logits');
    print('🔍 Softmax probabilities: $probabilities');
    return probabilities;
  }

  /// Extrae una descripción concisa utilizando varios patrones.
  String _extractDescription(String text, String predictedCategory) {
    List<RegExp> patterns = [
      RegExp(
          r'\b(?:gaste|gasté)\s+en\s+(?:un\s+|una\s+)?(?:el\s+|la\s+)?([A-Za-záéíóúÁÉÍÓÚñÑ]+)',
          caseSensitive: false),
      RegExp(
          r'\b(?:compre|compré)\s+(?:un\s+|una\s+)?(?:el\s+|la\s+)?([A-Za-záéíóúÁÉÍÓÚñÑ]+)',
          caseSensitive: false),
      RegExp(
          r'\b(?:en|por)\s+(?:el\s+|la\s+|los\s+|las\s+)?([A-Za-záéíóúÁÉÍÓÚñÑ]+)',
          caseSensitive: false),
    ];
    for (RegExp regExp in patterns) {
      Match? match = regExp.firstMatch(text);
      if (match != null) {
        String keyword = match.group(1)!;
        if (regExp.pattern.contains('compre') ||
            regExp.pattern.contains('compré')) {
          return 'Compré $keyword';
        }
        return 'Gasto en $keyword';
      }
    }
    return 'Gasto en ${predictedCategory.toLowerCase()}';
  }

  /// Realiza la inferencia del modelo TFLite.
  Map<String, dynamic> predict(String text) {
    try {
      print('-----------------------------------');
      print('📥 Texto original: $text');
      String normalizedText = _normalizeText(text);
      List<int> inputIds = _tokenizeBERT(normalizedText);
      List<int> attentionMask = inputIds
          .map((token) => token == vocabulary[padToken] ? 0 : 1)
          .toList();
      List<int> tokenTypeIds = List.filled(maxSeqLen, 0);

      print('🔍 Input IDs: $inputIds');
      print('🔍 Attention Mask: $attentionMask');
      print('🔍 Token Type IDs: $tokenTypeIds');

      // IMPORTANTE: El orden de entrada debe coincidir con el del modelo convertido.
      // Según la depuración, el primer tensor es "attention_mask",
      // el segundo "input_ids" y el tercero "token_type_ids".
      var inputIdsBuffer = [inputIds];
      var attentionMaskBuffer = [attentionMask];
      var tokenTypeIdsBuffer = [tokenTypeIds];
      var outputBuffer = [List.filled(categories.length, 0.0)];

      _interpreter.runForMultipleInputs(
        [attentionMaskBuffer, inputIdsBuffer, tokenTypeIdsBuffer],
        {0: outputBuffer},
      );

      List<double> logits = List<double>.from(outputBuffer[0]);
      List<double> probs = _softmax(logits);
      double maxProb = probs.reduce(math.max);
      int predictedIndex = probs.indexOf(maxProb);
      print('🔍 Índice predicho: $predictedIndex');
      String predictedCategory =
          (predictedIndex >= 0 && predictedIndex < categories.length)
              ? categories[predictedIndex]
              : "Desconocido";
      String confidence = (maxProb * 100).toStringAsFixed(1) + "%";
      print(
          '🔍 Categoría predicha: $predictedCategory con confianza $confidence');

      double amount = _extractAmount(normalizedText);
      String description =
          _extractDescription(normalizedText, predictedCategory);
      print('🔍 Descripción extraída: $description');
      print('-----------------------------------');
      return {
        'category': {
          'label': predictedCategory,
          'confidence': confidence,
        },
        'amount': amount.toStringAsFixed(2),
        'description': description,
      };
    } catch (e) {
      print('❌ Error en la predicción: $e');
      rethrow;
    }
  }

  /// Analiza múltiples gastos en un solo input dividiendo el texto.
  /// Analiza múltiples gastos en un solo input dividiendo el texto.
  List<Map<String, dynamic>> predictMultipleExpenses(String text) {
    List<Map<String, dynamic>> results = [];
    // Utilizamos una expresión regular que captura segmentos que comienzan con "gasté", "pagué" o "compré"
    // y que continúan hasta el inicio del siguiente gasto o el final del texto.
    RegExp exp = RegExp(
      r'((?:gast[eé]|pagu[eé]|compr[eé]).*?)(?=(?:gast[eé]|pagu[eé]|compr[eé])|$)',
      caseSensitive: false,
      dotAll: true,
    );
    Iterable<RegExpMatch> matches = exp.allMatches(text);
    List<String> segments = matches
        .map((match) => match.group(1)!.trim())
        .where(
            (segment) => segment.isNotEmpty && RegExp(r'\d').hasMatch(segment))
        .toList();

    for (String segment in segments) {
      results.add(predict(segment));
    }
    return results;
  }

  /// Imprime información de los tensores para depuración.
  void _debugModelInfo() {
    print('=== Input Tensors ===');
    _interpreter.getInputTensors().forEach((tensor) {
      print(
          'Name: ${tensor.name} - Shape: ${tensor.shape} - Type: ${tensor.type}');
    });
    print('=== Output Tensors ===');
    _interpreter.getOutputTensors().forEach((tensor) {
      print(
          'Name: ${tensor.name} - Shape: ${tensor.shape} - Type: ${tensor.type}');
    });
  }

  /// Libera la memoria del modelo.
  void dispose() {
    _interpreter.close();
    print('♻️ Model disposed');
  }
}
