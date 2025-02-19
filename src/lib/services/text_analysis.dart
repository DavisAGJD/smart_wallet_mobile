import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';

/// Clase para manejar todo el OCR y análisis de texto.
class TextAnalysis {
  static const Map<String, int> wordNumberMap = {
    'UNO': 1,
    'DOS': 2,
    'TRES': 3,
    'CUATRO': 4,
    'CINCO': 5,
    'SEIS': 6,
    'SIETE': 7,
    'OCHO': 8,
    'NUEVE': 9,
    'DIEZ': 10,
    'ONCE': 11,
    'DOCE': 12,
    'TRECE': 13,
    'CATORCE': 14,
    'QUINCE': 15,
    'DIECISEIS': 16,
    'DIECISIETE': 17,
    'DIECIOCHO': 18,
    'DIECINUEVE': 19,
    'VEINTE': 20,
    'TREINTA': 30,
    'CUARENTA': 40,
    'CINCUENTA': 50,
    'SESENTA': 60,
    'SETENTA': 70,
    'OCHENTA': 80,
    'NOVENTA': 90,
    'CIEN': 100,
    'MIL': 1000,
  };

  /// Procesa la imagen (rotación, redimensionado, etc.) para mejorar el OCR.
  static Future<File> processImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    // Rota la imagen 90 grados.
    image = img.copyRotate(image!, 90);

    // Redimensiona la imagen a un ancho de 2000 (mantiene la relación).
    image = img.copyResize(image, width: 2000);

    // Convierte a escala de grises.
    image = img.grayscale(image);

    // Ajusta el brillo.
    image = img.adjustColor(image, brightness: 1.1);

    // Normaliza la imagen (mejora contraste).
    image = img.normalize(image, 0, 255);

    // Aplica un filtro de enfoque (convolución).
    image = img.convolution(image, [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    final processedBytes = img.encodeJpg(image);
    return imageFile.writeAsBytes(processedBytes);
  }

  /// Realiza OCR local con Google ML Kit y devuelve el texto en mayúsculas.
  static Future<String> performOCR(File image) async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    await textRecognizer.close();

    return normalizeText(text);
  }

  /// Normaliza el texto (mayúsculas, quitar espacios extra, etc.).
  static String normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
  }

  /// Analiza el texto: detecta la tienda y el total.
  static Future<Map<String, dynamic>> analyzeText(String text) async {
    return {
      'store': detectStore(text),
      'total': extractTotal(text),
    };
  }

  /// Intenta detectar la tienda según patrones y similitud de cadenas.
  static String detectStore(String text) {
    const List<Map<String, String>> storePatterns = [
      {
        'pattern': r'(BODEGA\s*?AURRERA|BODEGAAURRERA|WAL\s*?MART)',
        'store': 'Bodega Aurrera'
      },
      {'pattern': r'(SORIANA|TIENDAS\s*SORIANA)', 'store': 'Soriana'},
      {
        'pattern': r'(OXXO|0XX0|UXXO|CADENA\s*COMERCIAL\s*OXXO)',
        'store': 'OXXO'
      },
      {'pattern': r'(SUPER\s*AKI|SURPER\s*AKI|AKI\s*GH)', 'store': 'Super Aki'},
      {
        'pattern': r'(WILLYS|ABARROTES\s*WILLYS|SUPER\s*WILLYS)',
        'store': 'Willys'
      },
      {
        'pattern': r'(DEL\s*SOL|DSU\s*S\.A\.|GRUPO\s*COMERCIAL\s*DSU)',
        'store': 'Del Sol'
      },
      {'pattern': r'(BBVA\s*MEXICO|BBA\d+)', 'store': 'BBVA'},
    ];

    // 1. Buscar patrones directos
    for (final entry in storePatterns) {
      if (RegExp(entry['pattern']!, caseSensitive: false).hasMatch(text)) {
        return entry['store']!;
      }
    }

    // 2. Similaridad de cadenas
    const List<String> candidates = [
      "OXXO",
      "Bodega Aurrera",
      "Soriana",
      "Super Aki",
      "Willys",
      "Del Sol",
      "BBVA",
    ];
    final ratings = candidates
        .map((candidate) => StringSimilarity.compareTwoStrings(text, candidate))
        .toList();
    final bestRating = ratings.reduce(max);
    final bestCandidate = candidates[ratings.indexOf(bestRating)];
    if (bestRating > 0.35) {
      return bestCandidate;
    }

    // 3. Claves de contexto
    const Map<String, String> contextClues = {
      r'RFC\s*[A-Z0-9]{12,14}': 'OXXO',
      r'UNIDAD\s*TIXCACAL': 'Bodega Aurrera',
      r'AVISO\s*DE\s*PRIVACIDAD': 'Soriana',
      r'GCD170101656': 'Del Sol',
      r'DELSOL\s*124': 'Del Sol',
      r'RFC\s*BBA[A-Z0-9]+': 'BBVA',
    };

    for (final entry in contextClues.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(text)) {
        return entry.value;
      }
    }

    return 'Desconocida';
  }

  /// Extrae el total usando varias estrategias, en orden de prioridad.
  static double? extractTotal(String text) {
    final strategies = [
      _totalFromImporteLine,
      _totalFromTotalLine,
      _totalFromCashDifference,
      _totalFromLargestNumber,
    ];

    final results = strategies.map((s) => s(text)).whereType<double>().toList();
    if (results.isEmpty) return null;

    // Escogemos la más frecuente (o la más repetida)
    final frequencyMap = <double, int>{};
    for (final num in results) {
      frequencyMap[num] = (frequencyMap[num] ?? 0) + 1;
    }

    return frequencyMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 1) Nueva estrategia: busca "IMPORTE" y un número en la misma o siguiente línea.
  static double? _totalFromImporteLine(String text) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('IMPORTE')) {
        // Buscar número en la misma línea
        final match = RegExp(r'(\d+[\.,]\d{2})').firstMatch(line);
        if (match != null) {
          return parseAmount(match.group(1));
        }
        // O buscar número en la línea siguiente
        if (i + 1 < lines.length) {
          final nextLineMatch =
              RegExp(r'(\d+[\.,]\d{2})').firstMatch(lines[i + 1]);
          if (nextLineMatch != null) {
            return parseAmount(nextLineMatch.group(1));
          }
        }
      }
    }
    return null;
  }

  /// 2) Busca líneas con la palabra "TOTAL" y un número en la misma o siguiente línea.
  static double? _totalFromTotalLine(String text) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('TOTAL')) {
        final match = RegExp(r'(\d+[\.,]\d{2})').firstMatch(lines[i]);
        if (match != null) return parseAmount(match.group(1));

        // A veces el total está en la siguiente línea
        if (i + 1 < lines.length) {
          final nextMatch = RegExp(r'(\d+[\.,]\d{2})').firstMatch(lines[i + 1]);
          if (nextMatch != null) return parseAmount(nextMatch.group(1));
        }
      }
    }
    return null;
  }

  /// 3) Calcula total si aparecen EFECTIVO - CAMBIO en el ticket.
  static double? _totalFromCashDifference(String text) {
    final efectivoMatch =
        RegExp(r'EFECTIVO\s+(\d+[\.,]\d{2})', caseSensitive: false)
            .firstMatch(text);
    final cambioMatch =
        RegExp(r'CAMBIO\s+(\d+[\.,]\d{2})', caseSensitive: false)
            .firstMatch(text);

    if (efectivoMatch != null && cambioMatch != null) {
      final efectivo = parseAmount(efectivoMatch.group(1));
      final cambio = parseAmount(cambioMatch.group(1));
      return (efectivo != null && cambio != null) ? (efectivo - cambio) : null;
    }
    return null;
  }

  /// 4) Toma el número más grande encontrado en todo el texto, ignorando "pago con".
  static double? _totalFromLargestNumber(String text) {
    final lines = text.split('\n');
    final allMatches = <double>[];

    for (final line in lines) {
      // Si la línea contiene "PAGO CON", la ignoramos (para no confundir con 200.00)
      if (line.contains('PAGO CON')) {
        continue;
      }

      final matches = RegExp(r'\d+[\.,]\d{2}').allMatches(line);
      for (final match in matches) {
        final parsed = parseAmount(match.group(0));
        if (parsed != null) {
          allMatches.add(parsed);
        }
      }
    }

    return allMatches.isNotEmpty ? allMatches.reduce(max) : null;
  }

  /// Convierte la cadena en double (sustituyendo ',' por '.').
  static double? parseAmount(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(RegExp(r'[^\d.,]'), '');
    return double.tryParse(cleaned.replaceFirst(',', '.'));
  }

  static bool isLikelyReceipt(String text) {
    const receiptKeywords = [
      'TOTAL',
      'SUBTOTAL',
      'IVA',
      'FECHA',
      'HORA',
      'NIT',
      'RFC',
      'CAMBIO',
      'EFECTIVO',
      'TICKET',
      'RECIBO',
      'VENTA',
      'TERMINAL',
      'AUTORIZACION'
    ];

    final lines = text.split('\n');
    final containsTotal = lines.any((line) =>
        line.contains(RegExp(r'TOTAL\s+[\d.,]', caseSensitive: false)));
    final keywordMatches =
        receiptKeywords.where((word) => text.contains(word)).length;

    // Consideramos recibo si:
    // - Tiene al menos 3 keywords de recibo
    // - Incluye un total válido
    // - Tiene formato de fecha/hora
    return keywordMatches >= 3 || containsTotal || _containsDateTime(text);
  }

  /// Busca patrones de fecha y hora
  static bool _containsDateTime(String text) {
    final datePattern = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{2,4})|'
        r'(\d{2}:\d{2}(:\d{2})?)\b');
    return datePattern.hasMatch(text);
  }
}
