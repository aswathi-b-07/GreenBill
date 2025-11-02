import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/constants.dart';
import '../data/models/bill_item.dart';

class BillData {
  final List<BillItem> items;
  final double total;
  final DateTime? date;

  BillData({
    required this.items,
    required this.total,
    this.date,
  });
}

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Helper to remove common currency/grouping characters so numbers like "1,234.56" and "₹123" parse correctly
  String _sanitizeForNumbers(String s) {
    try {
      var out = s.replaceAll(',', '');
      out = out.replaceAll('₹', '');
      out = out.replaceAll(RegExp(r'(?i)rs\.?'), '');
      // Keep digits and dots and spaces only for subsequent regexes
      out = out.replaceAll(RegExp(r'[^0-9\.\s]'), ' ');
      return out;
    } catch (e) {
      return s;
    }
  }

  List<double> _extractNumbers(String line) {
    final sanitized = _sanitizeForNumbers(line);
    final matches = RegExp(r'(\d+\.?\d*)').allMatches(sanitized);
    return matches.map((m) => double.tryParse(m.group(1) ?? '') ?? 0).where((d) => d > 0).toList();
  }

  Future<String> extractTextFromImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      print('Extracted text: ${recognizedText.text}');
      return recognizedText.text;
    } catch (e) {
      print('Error during OCR: $e');
      return '';
    }
  }

  /// Return the full RecognizedText object (blocks/lines/elements) for layout-aware parsing
  Future<RecognizedText?> extractRecognizedText(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      print('Error during OCR (recognized): $e');
      return null;
    }
  }

  /// Parse using ML Kit layout (line positions) to better associate names with prices
  Future<BillData> parseRecognizedText(RecognizedText recognizedText, String billType) async {
    try {
      // Collect lines with vertical position
      final lines = <Map<String, dynamic>>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          final top = line.boundingBox?.top ?? 0.0;
          lines.add({'text': text, 'y': top});
        }
      }

      // Sort by vertical position
      lines.sort((a, b) => (a['y'] as double).compareTo(b['y'] as double));

      final items = <BillItem>[];

      for (int i = 0; i < lines.length; i++) {
        final entry = lines[i];
        final text = (entry['text'] as String).replaceAll('\u00A0', ' ').trim();
        if (text.isEmpty) continue;

        final nums = _extractNumbers(text);
        final alpha = text.replaceAll(RegExp(r'[0-9\.,₹RsRs\.]'), '').trim();

        // Case 1: Line contains both words and numbers -> likely "name ... price"
        if (nums.isNotEmpty && alpha.isNotEmpty) {
          final total = nums.last;
          double quantity = 1.0;
          double unitPrice = total;
          if (nums.length >= 2) {
            // If first number is small, treat as quantity
            final first = nums.first;
            if (first > 0 && first <= 100) {
              quantity = first;
              unitPrice = total / quantity;
            }
          }

          final name = alpha.replaceAll(RegExp(r'[^A-Za-z0-9\s&-]'), '').trim();
          if (name.length > 1) {
            items.add(BillItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
              name: name,
              quantity: quantity,
              unitPrice: unitPrice,
              total: total,
            ));
          }
          continue;
        }

        // Case 2: Line is words only -> check next few lines for numeric-only lines to pair
        if (alpha.isNotEmpty && nums.isEmpty) {
          // look ahead up to 2 lines
          for (int j = i + 1; j <= i + 2 && j < lines.length; j++) {
            final nextText = (lines[j]['text'] as String).trim();
            final nextNums = _extractNumbers(nextText);
            if (nextNums.isNotEmpty) {
              final total = nextNums.last;
              final name = alpha.replaceAll(RegExp(r'[^A-Za-z0-9\s&-]'), '').trim();
              if (name.length > 1) {
                items.add(BillItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
                  name: name,
                  quantity: 1.0,
                  unitPrice: total,
                  total: total,
                ));
              }
              break;
            }
          }
        }
      }

      // Fallbacks: if no items found, use existing intelligent parsers on plain lines
      if (items.isEmpty) {
        final plain = recognizedText.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (billType == AppConstants.billTypePetrol) {
          return _parsePetrolBillIntelligent(plain);
        } else {
          return _parseGroceryBillIntelligent(plain);
        }
      }

      // Return data and let _applyEmissions filter/match to emission factors
      final data = BillData(items: items, total: items.fold(0.0, (s, it) => s + it.total));
      return await _applyEmissions(data, billType);
    } catch (e) {
      print('Error parsing recognized text: $e');
      return BillData(items: [], total: 0);
    }
  }

  Future<BillData> parseBillText(String text, String billType) async {
    try {
      print('Parsing bill text for type: $billType');
      print('Text to parse: $text');
      
      final lines = text.split('\n');
      final items = <BillItem>[];
      double total = 0;
      DateTime? date;

      // Clean and filter lines
      final cleanLines = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      print('Cleaned lines: $cleanLines');

      BillData parsed;
      if (billType == AppConstants.billTypePetrol) {
        parsed = _parsePetrolBillIntelligent(cleanLines);
      } else {
        parsed = _parseGroceryBillIntelligent(cleanLines);
      }

      // Map parsed items to known emission factors and compute carbon footprint
      final mapped = await _applyEmissions(parsed, billType);
      return mapped;
    } catch (e) {
      print('Error parsing bill text: $e');
      return BillData(items: [], total: 0);
    }
  }

  Future<BillData> _applyEmissions(BillData data, String billType) async {
    try {
      // Load emission maps from assets
      final foodJson = await rootBundle.loadString('assets/data/food_emission_factors.json');
      final fuelJson = await rootBundle.loadString('assets/data/fuel_emission_factors.json');
      final packagingJson = await rootBundle.loadString('assets/data/packaging_emission_factors.json');

      final Map<String, dynamic> foodMap = json.decode(foodJson) as Map<String, dynamic>;
      final Map<String, dynamic> fuelMap = json.decode(fuelJson) as Map<String, dynamic>;
      final Map<String, dynamic> packagingMap = json.decode(packagingJson) as Map<String, dynamic>;

      final List<BillItem> outItems = [];

      for (var item in data.items) {
        final nameNorm = item.name.toLowerCase();

        String? matchedCategory;
        double? factor;

        // For petrol bills, match against fuel map first
        if (billType == AppConstants.billTypePetrol) {
          for (var k in fuelMap.keys) {
            if (nameNorm.contains(k.toLowerCase()) || k.toLowerCase().contains(nameNorm)) {
              matchedCategory = k;
              factor = (fuelMap[k] as num).toDouble();
              break;
            }
          }
        }

        // For grocery bills, try food categories
        if (matchedCategory == null) {
          for (var k in foodMap.keys) {
            if (nameNorm.contains(k.toLowerCase()) || _tokenMatch(nameNorm, k.toLowerCase())) {
              matchedCategory = k;
              factor = (foodMap[k] as num).toDouble();
              break;
            }
          }
        }

        // Packaging fallback
        if (matchedCategory == null) {
          for (var k in packagingMap.keys) {
            if (nameNorm.contains(k.toLowerCase()) || _tokenMatch(nameNorm, k.toLowerCase())) {
              matchedCategory = k;
              factor = (packagingMap[k] as num).toDouble();
              break;
            }
          }
        }

        // If we found a factor, compute carbon footprint. Otherwise skip the item.
        if (factor != null) {
          final carbon = factor * (item.quantity);
          final newItem = item.copyWith(carbonFootprint: carbon, category: matchedCategory);
          outItems.add(newItem);
        } else {
          // No match; ignore this parsed line as it's not a known item
          print('Ignoring unknown item (no emission factor): ${item.name}');
        }
      }

      // If nothing mapped, return original (to allow debug screens to appear)
      if (outItems.isEmpty) {
        return data;
      }

      // Return BillData with filtered/mapped items
      return BillData(items: outItems, total: data.total, date: data.date);
    } catch (e) {
      print('Error applying emissions: $e');
      return data;
    }
  }

  bool _tokenMatch(String hay, String needle) {
    // Split into words and check if any word matches or needle appears in any word
    final hayTokens = hay.split(RegExp(r'[^a-z0-9]+')).where((s) => s.isNotEmpty).toList();
    final needleTokens = needle.split(RegExp(r'[^a-z0-9]+')).where((s) => s.isNotEmpty).toList();
    for (var nt in needleTokens) {
      for (var ht in hayTokens) {
        if (ht.contains(nt) || nt.contains(ht)) return true;
      }
    }
    return false;
  }

  /// Parse directly from an image file using ML Kit line blocks to
  /// preserve layout and improve pairing of item names with prices.
  Future<BillData> parseBillFromImage(XFile imageFile, String billType) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Build ordered list of lines (preserve layout)
      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          lines.add(line.text.trim());
        }
      }

      // Fallback to full text if no lines
      if (lines.isEmpty) {
        final full = recognizedText.text;
        return parseBillText(full, billType);
      }

      // Choose parser based on bill type
      if (billType == AppConstants.billTypePetrol) {
        return _parsePetrolBillLayoutAware(lines);
      } else {
        return _parseGroceryBillLayoutAware(lines);
      }
    } catch (e) {
      print('Error during layout-aware OCR parsing: $e');
      return BillData(items: [], total: 0);
    }
  }

  BillData _parseGroceryBillLayoutAware(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    String? lastNameLine;

    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final line = raw.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      if (date == null && (lower.contains('date') || lower.contains('time'))) {
        date = _extractDate(line) ?? date;
      }

      // total detection
      if (total == 0 && (lower.contains('total') || lower.contains('amount') || lower.contains('payable') || lower.contains('grand total'))) {
        final nums = _extractNumbers(line);
        if (nums.isNotEmpty) {
          total = nums.last;
        }
        continue;
      }

      // Try to find numbers in the line
      final nums = _extractNumbers(line);

      // If line contains an item AND a trailing price
      if (nums.isNotEmpty) {
        // find last numeric substring position
        final match = RegExp(r'(\d+[\.,]?\d*)\s*$').firstMatch(line.replaceAll(',', ''));
        if (match != null) {
          final priceStr = match.group(1) ?? '';
          final price = double.tryParse(priceStr) ?? nums.last;
          final idx = line.lastIndexOf(priceStr);
          final name = (idx > 0) ? line.substring(0, idx).trim() : lastNameLine ?? 'Item ${items.length + 1}';
          double quantity = 1.0;
          double unitPrice = price;

          // If there are two numbers and the earlier one looks like quantity
          if (nums.length >= 2) {
            final a = nums[0];
            final b = nums[nums.length - 1];
            // if first is small and second looks like total
            if (a > 0 && a <= 100 && b >= 0) {
              quantity = a;
              unitPrice = (b / quantity);
            }
          }

          // Avoid nonsense names
          final cleanName = name.replaceAll(RegExp(r'[^A-Za-z0-9\s&-]'), '').trim();
          if (cleanName.length > 0 && price > 0) {
            items.add(BillItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
              name: cleanName,
              quantity: quantity,
              unitPrice: unitPrice,
              total: price,
            ));
          }

          lastNameLine = null;
          continue;
        }

        // If line is like "2000 20.00" (numbers only) and previous line contains name
        final onlyNumbers = RegExp(r'^[\d\s\.,]+$').hasMatch(line.replaceAll(',', ''));
        if (onlyNumbers && lastNameLine != null) {
          final parts = _extractNumbers(line);
          if (parts.isNotEmpty) {
            final qty = parts.length >= 2 ? parts[0] : 1.0;
            final tot = parts.length >= 2 ? parts[1] : parts[0];
            items.add(BillItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
              name: lastNameLine,
              quantity: qty,
              unitPrice: tot / (qty > 0 ? qty : 1.0),
              total: tot,
            ));
            lastNameLine = null;
            continue;
          }
        }
      }

      // If line looks like a name (letters and spaces) store as potential name
      if (RegExp(r'^[A-Za-z\s&\-]{3,}$').hasMatch(line)) {
        lastNameLine = line;
      }
    }

    // compute total if not found
    if (total == 0 && items.isNotEmpty) {
      total = items.fold(0.0, (s, it) => s + it.total);
    }

    return BillData(items: items, total: total, date: date);
  }

  BillData _parsePetrolBillLayoutAware(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    // collect candidate numeric lines
    final candidates = <Map<String, dynamic>>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (date == null && (lower.contains('date') || lower.contains('time'))) {
        date = _extractDate(line) ?? date;
      }
      final nums = _extractNumbers(line);
      if (nums.isNotEmpty) {
        candidates.add({'index': i, 'line': line, 'nums': nums});
      }
      if (lower.contains('total') || lower.contains('amount')) {
        final n = _extractNumbers(line);
        if (n.isNotEmpty) total = n.last;
      }
    }

    // Try to find pattern: small number (litres) and a larger number (amount) on same or adjacent lines
    for (int i = 0; i < candidates.length; i++) {
      final entry = candidates[i];
      final nums = (entry['nums'] as List<double>);
      if (nums.length >= 2) {
        // If first is liters (<=100) and second is amount
        if (nums[0] > 0 && nums[0] <= 100 && nums[1] > nums[0]) {
          final liters = nums[0];
          final amount = nums[1];
          final unitPrice = amount / liters;
          items.add(BillItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Petrol',
            quantity: liters,
            unitPrice: unitPrice,
            total: amount,
          ));
          if (total == 0) total = amount;
          break;
        }
      }

      // Try neighbouring entries
      if (i < candidates.length - 1) {
        final n1 = (candidates[i]['nums'] as List<double>);
        final n2 = (candidates[i + 1]['nums'] as List<double>);
        if (n1.isNotEmpty && n2.isNotEmpty) {
          final small = n1.first <= 100 ? n1.first : (n2.first <= 100 ? n2.first : null);
          final large = (n2..sort()).lastWhere((v) => v >= (small ?? 0), orElse: () => n2.last);
          if (small != null && large != null && large > small) {
            final liters = small;
            final amount = large;
            final unitPrice = amount / liters;
            items.add(BillItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'Petrol',
              quantity: liters,
              unitPrice: unitPrice,
              total: amount,
            ));
            if (total == 0) total = amount;
            break;
          }
        }
      }
    }

    return BillData(items: items, total: total, date: date);
  }

  BillData _parsePetrolBill(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    double? liters;
    double? pricePerLiter;
    String fuelType = 'Petrol';

    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for date
      if (date == null && (lowerLine.contains('date') || lowerLine.contains('time'))) {
        date = _extractDate(line);
      }

      // Look for fuel type
      if (lowerLine.contains('diesel')) {
        fuelType = 'Diesel';
      } else if (lowerLine.contains('petrol') || lowerLine.contains('gasoline')) {
        fuelType = 'Petrol';
      }

      // Look for liters - multiple patterns
      if (lowerLine.contains('ltr') || lowerLine.contains('liters') || lowerLine.contains('litre')) {
        final literMatch = RegExp(r'(\d+\.?\d*)\s*(ltr|liters?|litre)').firstMatch(lowerLine);
        if (literMatch != null) {
          liters = double.tryParse(literMatch.group(1) ?? '');
        }
      }

      // Look for price per liter
      if (lowerLine.contains('rate') || lowerLine.contains('per') || lowerLine.contains('price')) {
        final priceMatch = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (priceMatch != null) {
          pricePerLiter = double.tryParse(priceMatch.group(1) ?? '');
        }
      }

      // Look for total amount - multiple patterns
      if (lowerLine.contains('total') || lowerLine.contains('amount') || lowerLine.contains('payable')) {
        final totalMatch = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (totalMatch != null) {
          total = double.tryParse(totalMatch.group(1) ?? '') ?? 0;
        }
      }
    }

    // Create bill item for fuel
    if (liters != null && liters > 0) {
      items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fuelType,
        quantity: liters,
        unitPrice: pricePerLiter ?? (total > 0 ? total / liters : 0),
        total: total > 0 ? total : (pricePerLiter ?? 0) * liters,
      ));
    }

    return BillData(
      items: items,
      total: total,
      date: date,
    );
  }

  BillData _parseGroceryBill(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    // Skip header lines and look for item lines
    bool inItemsSection = false;
    bool foundTotal = false;

    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for date
      if (date == null && (lowerLine.contains('date') || lowerLine.contains('time'))) {
        date = _extractDate(line);
      }

      // Detect start of items section
      if (!inItemsSection && (lowerLine.contains('item') || lowerLine.contains('product') || 
          lowerLine.contains('description') || lowerLine.contains('qty') || lowerLine.contains('rate'))) {
        inItemsSection = true;
        continue;
      }

      // Look for total
      if (!foundTotal && (lowerLine.contains('total') || lowerLine.contains('amount') || 
          lowerLine.contains('payable') || lowerLine.contains('grand total'))) {
        final totalMatch = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (totalMatch != null) {
          total = double.tryParse(totalMatch.group(1) ?? '') ?? 0;
          foundTotal = true;
        }
        continue;
      }

      // Skip if not in items section
      if (!inItemsSection) continue;

      // Parse item lines - multiple patterns
      final itemData = _parseItemLine(line);
      if (itemData != null) {
        items.add(BillItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
          name: itemData['name']!,
          quantity: itemData['quantity']!,
          unitPrice: itemData['unitPrice']!,
          total: itemData['total']!,
        ));
      }
    }

    // If no items found, try alternative parsing
    if (items.isEmpty) {
      return _parseGroceryBillAlternative(lines);
    }

    return BillData(
      items: items,
      total: total,
      date: date,
    );
  }

  BillData _parseGroceryBillAlternative(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for date
      if (date == null && (lowerLine.contains('date') || lowerLine.contains('time'))) {
        date = _extractDate(line);
      }

      // Look for total
      if (lowerLine.contains('total') || lowerLine.contains('amount') || lowerLine.contains('payable')) {
        final totalMatch = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (totalMatch != null) {
          total = double.tryParse(totalMatch.group(1) ?? '') ?? 0;
        }
      }

      // Try to parse any line that looks like an item
      final itemData = _parseItemLine(line);
      if (itemData != null) {
        items.add(BillItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
          name: itemData['name']!,
          quantity: itemData['quantity']!,
          unitPrice: itemData['unitPrice']!,
          total: itemData['total']!,
        ));
      }
    }

    return BillData(
      items: items,
      total: total,
      date: date,
    );
  }

  Map<String, dynamic>? _parseItemLine(String line) {
    // Clean the line
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    // Skip common non-item lines
    final lowerLine = cleanLine.toLowerCase();
    if (lowerLine.contains('total') || lowerLine.contains('subtotal') || 
        lowerLine.contains('tax') || lowerLine.contains('discount') ||
        lowerLine.contains('amount') || lowerLine.contains('payable') ||
        lowerLine.contains('date') || lowerLine.contains('time') ||
        lowerLine.contains('bill no') || lowerLine.contains('invoice') ||
        lowerLine.contains('thank') || lowerLine.contains('visit') ||
        lowerLine.contains('cash') || lowerLine.contains('card') ||
        lowerLine.contains('change') || lowerLine.contains('balance')) {
      return null;
    }

    // Pattern 1: Item Name Quantity Unit Price (most common)
    var match = RegExp(r'^([A-Za-z\s&]+?)\s+(\d+\.?\d*)\s*(kg|g|l|ml|pcs?|pc|nos?|no|pkt|pack|bottle|btl|can|tin|box|bag)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final quantity = double.parse(match.group(2) ?? '1');
      final unit = match.group(3)?.toLowerCase() ?? 'kg';
      final price = double.parse(match.group(4) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': _convertToKg(quantity, unit),
          'unitPrice': price / _convertToKg(quantity, unit),
          'total': price,
        };
      }
    }

    // Pattern 2: Item Name @ Price Quantity Total
    match = RegExp(r'^([A-Za-z\s&]+?)\s+@\s*₹?\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final unitPrice = double.parse(match.group(2) ?? '0');
      final quantity = double.parse(match.group(3) ?? '1');
      final total = double.parse(match.group(4) ?? '0');
      
      if (name.length > 2 && total > 0) {
        return {
          'name': name,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'total': total,
        };
      }
    }

    // Pattern 3: Item Name Quantity Price (space separated)
    match = RegExp(r'^([A-Za-z\s&]+?)\s+(\d+\.?\d*)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final quantity = double.parse(match.group(2) ?? '1');
      final price = double.parse(match.group(3) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': quantity,
          'unitPrice': price / quantity,
          'total': price,
        };
      }
    }

    // Pattern 4: Item Name with Price at end
    match = RegExp(r'^([A-Za-z\s&]+?)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final price = double.parse(match.group(2) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': 1.0,
          'unitPrice': price,
          'total': price,
        };
      }
    }

    // Pattern 5: Tab-separated or fixed-width format
    final parts = cleanLine.split(RegExp(r'\s{2,}|\t'));
    if (parts.length >= 3) {
      final name = parts[0].trim();
      final quantityStr = parts[1].trim();
      final priceStr = parts[parts.length - 1].replaceAll(RegExp(r'[^\d\.]'), '');
      
      if (name.length > 2 && priceStr.isNotEmpty) {
        final quantity = double.tryParse(quantityStr) ?? 1.0;
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (price > 0) {
          return {
            'name': name,
            'quantity': quantity,
            'unitPrice': price / quantity,
            'total': price,
          };
        }
      }
    }

    // Pattern 6: Look for any line with a price at the end
    match = RegExp(r'^(.+?)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final price = double.parse(match.group(2) ?? '0');
      
      // Filter out obvious non-items
      if (name.length > 2 && price > 0 && 
          !name.toLowerCase().contains('total') &&
          !name.toLowerCase().contains('subtotal') &&
          !name.toLowerCase().contains('tax') &&
          !name.toLowerCase().contains('discount')) {
        return {
          'name': name,
          'quantity': 1.0,
          'unitPrice': price,
          'total': price,
        };
      }
    }

    return null;
  }

  double _convertToKg(double quantity, String unit) {
    switch (unit.toLowerCase()) {
      case 'g':
        return quantity / 1000;
      case 'ml':
        return quantity / 1000;
      case 'l':
      case 'ltr':
      case 'litre':
      case 'liters':
        return quantity;
      case 'pcs':
      case 'pc':
      case 'nos':
      case 'no':
      case 'pkt':
      case 'pack':
      case 'bottle':
      case 'btl':
      case 'can':
      case 'tin':
      case 'box':
      case 'bag':
        return quantity;
      default:
        return quantity;
    }
  }

  DateTime? _extractDate(String line) {
    try {
      // Try different date formats
      final patterns = [
        RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})'),
        RegExp(r'(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})'),
        RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final parts = [match.group(1)!, match.group(2)!, match.group(3)!];
          int day, month, year;
          
          if (parts[2].length == 4) {
            // Format: DD/MM/YYYY or YYYY/MM/DD
            if (int.parse(parts[0]) > 12) {
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]);
            } else {
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
              day = int.parse(parts[2]);
            }
          } else {
            // Format: DD/MM/YY
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
            year = 2000 + int.parse(parts[2]);
          }
          
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  BillData _parsePetrolBillIntelligent(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    // Extract all numbers and their context
    final numbers = <Map<String, dynamic>>[];
    String fuelType = 'Petrol';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      
      // Look for date
      if (date == null && (lowerLine.contains('date') || lowerLine.contains('time'))) {
        date = _extractDate(line);
      }

      // Look for fuel type
      if (lowerLine.contains('diesel')) {
        fuelType = 'Diesel';
      } else if (lowerLine.contains('petrol') || lowerLine.contains('gasoline')) {
        fuelType = 'Petrol';
      }

      // Extract all numbers with context (sanitized to handle commas/currency)
      final extractedNums = _extractNumbers(line);
      for (var num in extractedNums) {
        numbers.add({
          'value': num,
          'line': line,
          'index': i,
          'position': 0,
        });
      }
    }

    print('Extracted numbers: $numbers');

    // Find liters and amounts by analyzing number patterns
    double? liters;
    double? amount;
    // Filter out numbers that come from lines likely to be dates, bill numbers or other metadata
    final filteredNumbers = numbers.where((n) {
      final l = (n['line'] as String).toLowerCase();
      if (l.contains('date') || l.contains('time') || l.contains('bill no') || l.contains('invoice')) return false;
      return true;
    }).toList();

    // Look for patterns like "45.50" followed by "4185.75" (liters and amount) using filtered numbers
    for (int i = 0; i < filteredNumbers.length - 1; i++) {
      final num1 = filteredNumbers[i]['value'] as double;
      final num2 = filteredNumbers[i + 1]['value'] as double;

      // Prefer a small num (likely liters) and a larger num (likely amount). Use thresholds to avoid date artifacts.
      if (num1 > 0 && num1 < 100 && num2 > num1 * 2) {
        liters = num1;
        amount = num2;
        print('Found potential liters: $liters, amount: $amount');
        break;
      }
    }

    // If we didn't find the pattern, try to pick a reasonable amount (largest sensible monetary value)
    if (amount == null && filteredNumbers.isNotEmpty) {
      final numericList = filteredNumbers.map((n) => n['value'] as double).where((v) => v > 0).toList();
      numericList.sort();
      // pick the largest number that is greater than a minimum monetary threshold
      amount = numericList.lastWhere((v) => v >= 10, orElse: () => numericList.isNotEmpty ? numericList.last : 0);
      print('Using selected number as amount: $amount');
    }

    // If we still don't have liters, try to find a reasonable value
    if (liters == null && filteredNumbers.isNotEmpty) {
      // Look for numbers between 1 and 100 (reasonable liter range), preferring decimals
      final candidateLiters = filteredNumbers
          .map((n) => n['value'] as double)
          .where((n) => n >= 1 && n <= 100)
          .toList();
      if (candidateLiters.isNotEmpty) {
        liters = candidateLiters.first;
        print('Using candidate liters: $liters');
      }
    }

    // Create bill item for fuel
    if (liters != null && liters > 0) {
      final unitPrice = amount != null ? amount / liters : 0;
      final itemTotal = amount ?? (unitPrice * liters);
      
      items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fuelType,
        quantity: liters,
        unitPrice: unitPrice.toDouble(),
        total: itemTotal,
      ));
      
      total = itemTotal;
      print('Created fuel item: $fuelType, ${liters}L, ₹${unitPrice.toStringAsFixed(2)}/L, Total: ₹${itemTotal.toStringAsFixed(2)}');
    }

    return BillData(
      items: items,
      total: total,
      date: date,
    );
  }

  BillData _parseGroceryBillIntelligent(List<String> lines) {
    final items = <BillItem>[];
    double total = 0;
    DateTime? date;

    // Extract all numbers and their context
    final numbers = <Map<String, dynamic>>[];
    final potentialItems = <Map<String, dynamic>>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      
      // Look for date
      if (date == null && (lowerLine.contains('date') || lowerLine.contains('time'))) {
        date = _extractDate(line);
      }

      // Look for total
      if (lowerLine.contains('total') || lowerLine.contains('amount') || 
          lowerLine.contains('payable') || lowerLine.contains('grand total')) {
        final totalMatch = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (totalMatch != null) {
          total = double.tryParse(totalMatch.group(1) ?? '') ?? 0;
        }
        continue;
      }

      // Extract all numbers with context (sanitized to handle commas/currency)
      final extractedNums = _extractNumbers(line);
      for (var num in extractedNums) {
        numbers.add({
          'value': num,
          'line': line,
          'index': i,
          'position': 0,
        });
      }

      // Try to parse item line
      final itemData = _parseItemLineIntelligent(line);
      if (itemData != null) {
        potentialItems.add(itemData);
      }
    }

    print('Extracted numbers: $numbers');
    print('Potential items: $potentialItems');

    // If we found items through intelligent parsing, use them
    if (potentialItems.isNotEmpty) {
      for (var itemData in potentialItems) {
        items.add(BillItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: itemData['name'],
          quantity: itemData['quantity'],
          unitPrice: (itemData['unitPrice'] as num).toDouble(),
          total: itemData['total'],
        ));
      }
    } else {
      // For grocery bills, try to extract specific food items
      final foodItems = _extractFoodItems(lines);
      
      if (foodItems.isNotEmpty) {
        for (var foodItem in foodItems) {
          items.add(BillItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: foodItem['name'],
            quantity: foodItem['quantity'],
            unitPrice: foodItem['unitPrice'],
            total: foodItem['total'],
          ));
        }
      } else {
        // Fallback: try to create items from number patterns with better names
        final sortedNumbers = numbers.map((n) => n['value'] as double).toList()..sort();
        
        // Look for reasonable item prices (not too large, not too small)
        final itemPrices = sortedNumbers.where((n) => n >= 5 && n <= 1000).toList();
        
        // Try to extract item names from the text
        final potentialItemNames = _extractPotentialItemNames(lines);
        
        for (int i = 0; i < itemPrices.take(3).length; i++) { // Limit to 3 items
          final price = itemPrices[i];
          final itemName = i < potentialItemNames.length 
              ? potentialItemNames[i] 
              : 'Grocery Item ${i + 1}';
              
          items.add(BillItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: itemName,
            quantity: 1.0,
            unitPrice: price.toDouble(),
            total: price,
          ));
        }
      }
    }

    // Calculate total if not found
    if (total == 0 && items.isNotEmpty) {
      total = items.fold(0.0, (sum, item) => sum + item.total);
    }

    return BillData(
      items: items,
      total: total,
      date: date,
    );
  }

  Map<String, dynamic>? _parseItemLineIntelligent(String line) {
    // Clean the line
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    // Skip common non-item lines
    final lowerLine = cleanLine.toLowerCase();
    if (lowerLine.contains('total') || lowerLine.contains('subtotal') || 
        lowerLine.contains('tax') || lowerLine.contains('discount') ||
        lowerLine.contains('amount') || lowerLine.contains('payable') ||
        lowerLine.contains('date') || lowerLine.contains('time') ||
        lowerLine.contains('bill no') || lowerLine.contains('invoice') ||
        lowerLine.contains('thank') || lowerLine.contains('visit') ||
        lowerLine.contains('cash') || lowerLine.contains('card') ||
        lowerLine.contains('change') || lowerLine.contains('balance') ||
        lowerLine.contains('vat') || lowerLine.contains('gst') ||
        lowerLine.contains('quantity') || lowerLine.contains('purchase') ||
        lowerLine.contains('essentials') || lowerLine.contains('grocery') ||
        lowerLine.contains('supermarket') || lowerLine.contains('store') ||
        lowerLine.contains('shop') || lowerLine.contains('market') ||
        lowerLine.contains('fresh') || lowerLine.contains('mixed') ||
        lowerLine.contains('organic') || lowerLine.contains('local')) {
      return null;
    }

    // Pattern 1: Item Name Quantity Unit Price (most common)
    var match = RegExp(r'^([A-Za-z\s&]+?)\s+(\d+\.?\d*)\s*(kg|g|l|ml|pcs?|pc|nos?|no|pkt|pack|bottle|btl|can|tin|box|bag)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final quantity = double.parse(match.group(2) ?? '1');
      final unit = match.group(3)?.toLowerCase() ?? 'kg';
      final price = double.parse(match.group(4) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': _convertToKg(quantity, unit),
          'unitPrice': price / _convertToKg(quantity, unit),
          'total': price,
        };
      }
    }

    // Pattern 2: Item Name @ Price Quantity Total
    match = RegExp(r'^([A-Za-z\s&]+?)\s+@\s*₹?\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final unitPrice = double.parse(match.group(2) ?? '0');
      final quantity = double.parse(match.group(3) ?? '1');
      final total = double.parse(match.group(4) ?? '0');
      
      if (name.length > 2 && total > 0) {
        return {
          'name': name,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'total': total,
        };
      }
    }

    // Pattern 3: Item Name Quantity Price (space separated)
    match = RegExp(r'^([A-Za-z\s&]+?)\s+(\d+\.?\d*)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final quantity = double.parse(match.group(2) ?? '1');
      final price = double.parse(match.group(3) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': quantity,
          'unitPrice': price / quantity,
          'total': price,
        };
      }
    }

    // Pattern 4: Item Name with Price at end
    match = RegExp(r'^([A-Za-z\s&]+?)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final price = double.parse(match.group(2) ?? '0');
      
      if (name.length > 2 && price > 0) {
        return {
          'name': name,
          'quantity': 1.0,
          'unitPrice': price,
          'total': price,
        };
      }
    }

    // Pattern 5: Tab-separated or fixed-width format
    final parts = cleanLine.split(RegExp(r'\s{2,}|\t'));
    if (parts.length >= 3) {
      final name = parts[0].trim();
      final quantityStr = parts[1].trim();
      final priceStr = parts[parts.length - 1].replaceAll(RegExp(r'[^\d\.]'), '');
      
      if (name.length > 2 && priceStr.isNotEmpty) {
        final quantity = double.tryParse(quantityStr) ?? 1.0;
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (price > 0) {
          return {
            'name': name,
            'quantity': quantity,
            'unitPrice': price / quantity,
            'total': price,
          };
        }
      }
    }

    // Pattern 6: Look for any line with a price at the end
    match = RegExp(r'^(.+?)\s+₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final price = double.parse(match.group(2) ?? '0');
      
      // Filter out obvious non-items
      if (name.length > 2 && price > 0 && 
          !name.toLowerCase().contains('total') &&
          !name.toLowerCase().contains('subtotal') &&
          !name.toLowerCase().contains('tax') &&
          !name.toLowerCase().contains('discount')) {
        return {
          'name': name,
          'quantity': 1.0,
          'unitPrice': price,
          'total': price,
        };
      }
    }

    return null;
  }

  List<String> _extractPotentialItemNames(List<String> lines) {
    final itemNames = <String>[];
    
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      final lowerLine = cleanLine.toLowerCase();
      
      // Skip common non-item lines
      if (lowerLine.contains('total') || lowerLine.contains('subtotal') || 
          lowerLine.contains('tax') || lowerLine.contains('discount') ||
          lowerLine.contains('amount') || lowerLine.contains('payable') ||
          lowerLine.contains('date') || lowerLine.contains('time') ||
          lowerLine.contains('bill no') || lowerLine.contains('invoice') ||
          lowerLine.contains('thank') || lowerLine.contains('visit') ||
          lowerLine.contains('cash') || lowerLine.contains('card') ||
          lowerLine.contains('change') || lowerLine.contains('balance') ||
          lowerLine.contains('quantity') || lowerLine.contains('vat') ||
          lowerLine.contains('gst') || lowerLine.contains('purchase')) {
        continue;
      }
      
      // Look for specific grocery item patterns
      // Pattern 1: "FRESH MEAT 2.5 KG" -> "FRESH MEAT"
      if (RegExp(r'^[A-Z\s]+\s+\d+\.?\d*\s*(KG|G|L|ML|PCS|PC|NOS|NO)$').hasMatch(cleanLine)) {
        final match = RegExp(r'^([A-Z\s]+)\s+\d+\.?\d*\s*(KG|G|L|ML|PCS|PC|NOS|NO)$').firstMatch(cleanLine);
        if (match != null) {
          final itemName = match.group(1)?.trim();
          if (itemName != null && itemName.length > 2) {
            itemNames.add(itemName);
          }
        }
      }
      // Pattern 2: "MIXED DAIRY 4 PCS" -> "MIXED DAIRY"
      else if (RegExp(r'^[A-Z\s]+\s+\d+\s*(PCS|PC|NOS|NO)$').hasMatch(cleanLine)) {
        final match = RegExp(r'^([A-Z\s]+)\s+\d+\s*(PCS|PC|NOS|NO)$').firstMatch(cleanLine);
        if (match != null) {
          final itemName = match.group(1)?.trim();
          if (itemName != null && itemName.length > 2) {
            itemNames.add(itemName);
          }
        }
      }
      // Pattern 3: Lines with food-related keywords
      else if (cleanLine.length > 3 && 
               (lowerLine.contains('meat') || lowerLine.contains('dairy') || 
                lowerLine.contains('fresh') || lowerLine.contains('mixed') ||
                lowerLine.contains('organic') || lowerLine.contains('local') ||
                lowerLine.contains('chicken') || lowerLine.contains('beef') ||
                lowerLine.contains('milk') || lowerLine.contains('cheese') ||
                lowerLine.contains('bread') || lowerLine.contains('rice') ||
                lowerLine.contains('vegetable') || lowerLine.contains('fruit'))) {
        
        // Extract potential item name (remove common suffixes)
        String itemName = cleanLine
            .replaceAll(RegExp(r'\s+\d+\.?\d*\s*$'), '') // Remove trailing numbers
            .replaceAll(RegExp(r'\s+kg\s*$'), '') // Remove kg suffix
            .replaceAll(RegExp(r'\s+g\s*$'), '') // Remove g suffix
            .replaceAll(RegExp(r'\s+ml\s*$'), '') // Remove ml suffix
            .replaceAll(RegExp(r'\s+l\s*$'), '') // Remove l suffix
            .replaceAll(RegExp(r'\s+pcs\s*$'), '') // Remove pcs suffix
            .replaceAll(RegExp(r'\s+pc\s*$'), '') // Remove pc suffix
            .replaceAll(RegExp(r'\s+nos\s*$'), '') // Remove nos suffix
            .replaceAll(RegExp(r'\s+no\s*$'), '') // Remove no suffix
            .trim();
            
        if (itemName.length > 2 && itemName.length < 50) {
          itemNames.add(itemName);
        }
      }
    }
    
    return itemNames.take(10).toList(); // Limit to 10 potential names
  }

  List<Map<String, dynamic>> _extractFoodItems(List<String> lines) {
    final foodItems = <Map<String, dynamic>>[];
    
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      final lowerLine = cleanLine.toLowerCase();
      
      // Skip non-food lines
      if (lowerLine.contains('total') || lowerLine.contains('subtotal') || 
          lowerLine.contains('tax') || lowerLine.contains('discount') ||
          lowerLine.contains('amount') || lowerLine.contains('payable') ||
          lowerLine.contains('date') || lowerLine.contains('time') ||
          lowerLine.contains('bill no') || lowerLine.contains('invoice') ||
          lowerLine.contains('thank') || lowerLine.contains('visit') ||
          lowerLine.contains('cash') || lowerLine.contains('card') ||
          lowerLine.contains('change') || lowerLine.contains('balance') ||
          lowerLine.contains('vat') || lowerLine.contains('gst') ||
          lowerLine.contains('quantity') || lowerLine.contains('purchase') ||
          lowerLine.contains('essentials') || lowerLine.contains('grocery') ||
          lowerLine.contains('supermarket') || lowerLine.contains('store') ||
          lowerLine.contains('shop') || lowerLine.contains('market')) {
        continue;
      }
      
      // Look for specific food item patterns
      // Pattern 1: "FRESH MEAT 2.5 KG" with price
      var match = RegExp(r'^([A-Z\s]+)\s+(\d+\.?\d*)\s*(KG|G|L|ML|PCS|PC|NOS|NO)\s*₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
      if (match != null) {
        final name = match.group(1)?.trim();
        final quantity = double.tryParse(match.group(2) ?? '1') ?? 1.0;
        final unit = match.group(3)?.toLowerCase() ?? 'kg';
        final price = double.tryParse(match.group(4) ?? '0') ?? 0.0;
        
        if (name != null && name.length > 2 && price > 0) {
          foodItems.add({
            'name': name,
            'quantity': _convertToKg(quantity, unit),
            'unitPrice': price / _convertToKg(quantity, unit),
            'total': price,
          });
        }
      }
      // Pattern 2: "MIXED DAIRY 4 PCS" with price
      else if (RegExp(r'^([A-Z\s]+)\s+(\d+)\s*(PCS|PC|NOS|NO)\s*₹?\s*(\d+\.?\d*)$').hasMatch(cleanLine)) {
        match = RegExp(r'^([A-Z\s]+)\s+(\d+)\s*(PCS|PC|NOS|NO)\s*₹?\s*(\d+\.?\d*)$').firstMatch(cleanLine);
        if (match != null) {
          final name = match.group(1)?.trim();
          final quantity = double.tryParse(match.group(2) ?? '1') ?? 1.0;
          final unit = match.group(3)?.toLowerCase() ?? 'pcs';
          final price = double.tryParse(match.group(4) ?? '0') ?? 0.0;
          
          if (name != null && name.length > 2 && price > 0) {
            foodItems.add({
              'name': name,
              'quantity': quantity,
              'unitPrice': price / quantity,
              'total': price,
            });
          }
        }
      }
      // Pattern 3: Food items with common food keywords
      else if (cleanLine.length > 3 && 
               (lowerLine.contains('meat') || lowerLine.contains('dairy') || 
                lowerLine.contains('chicken') || lowerLine.contains('beef') ||
                lowerLine.contains('milk') || lowerLine.contains('cheese') ||
                lowerLine.contains('bread') || lowerLine.contains('rice') ||
                lowerLine.contains('vegetable') || lowerLine.contains('fruit') ||
                lowerLine.contains('apple') || lowerLine.contains('banana') ||
                lowerLine.contains('tomato') || lowerLine.contains('onion') ||
                lowerLine.contains('potato') || lowerLine.contains('carrot'))) {
        
        // Try to extract quantity and price
        final quantityMatch = RegExp(r'(\d+\.?\d*)\s*(kg|g|l|ml|pcs|pc|nos|no)').firstMatch(cleanLine);
        final priceMatch = RegExp(r'₹?\s*(\d+\.?\d*)').firstMatch(cleanLine);
        
        if (quantityMatch != null && priceMatch != null) {
          final name = cleanLine
              .replaceAll(RegExp(r'\s+\d+\.?\d*\s*(kg|g|l|ml|pcs|pc|nos|no)'), '')
              .replaceAll(RegExp(r'₹?\s*\d+\.?\d*'), '')
              .trim();
          
          final quantity = double.tryParse(quantityMatch.group(1) ?? '1') ?? 1.0;
          final unit = quantityMatch.group(2)?.toLowerCase() ?? 'kg';
          final price = double.tryParse(priceMatch.group(1) ?? '0') ?? 0.0;
          
          if (name.length > 2 && price > 0) {
            foodItems.add({
              'name': name,
              'quantity': _convertToKg(quantity, unit),
              'unitPrice': price / _convertToKg(quantity, unit),
              'total': price,
            });
          }
        }
      }
    }
    
    return foodItems.take(5).toList(); // Limit to 5 food items
  }

  void dispose() {
    _textRecognizer.close();
  }
}