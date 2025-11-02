import '../services/ocr_service.dart';
import '../utils/constants.dart';

class OCRTestHelper {
  static final OCRService _ocrService = OCRService();

  static Future<void> testSampleBills() async {
    print('=== OCR Test Helper ===');
    
    // Test sample grocery bill text
    final groceryBillText = '''
SUPERMARKET BILL
Date: 15/12/2024
Time: 14:30

Rice 2.5 kg ₹120.00
Wheat Flour 1.0 kg ₹45.00
Milk 1.0 l ₹60.00
Bread 2.0 pcs ₹40.00
Tomatoes 0.5 kg ₹25.00
Onions 1.0 kg ₹30.00
Potatoes 2.0 kg ₹40.00
Oil 1.0 l ₹180.00

Subtotal: ₹520.00
Tax: ₹52.00
Total: ₹572.00

Thank you for shopping!
''';

    print('Testing Grocery Bill Parsing:');
    print('Input text: $groceryBillText');
    
    final groceryResult = await _ocrService.parseBillText(groceryBillText, AppConstants.billTypeGrocery);
    print('Parsed items: ${groceryResult.items.length}');
    for (var item in groceryResult.items) {
      print('  - ${item.name}: ${item.quantity} kg, ₹${item.unitPrice.toStringAsFixed(2)}/kg, Total: ₹${item.total.toStringAsFixed(2)}');
    }
    print('Total: ₹${groceryResult.total}');
    print('Date: ${groceryResult.date}');
    print('');

    // Test sample petrol bill text
    final petrolBillText = '''
PETROL PUMP RECEIPT
Date: 15/12/2024
Time: 10:15

Petrol: 25.5 ltr @ ₹95.50/ltr
Amount: ₹2435.25

Thank you for visiting!
''';

    print('Testing Petrol Bill Parsing:');
    print('Input text: $petrolBillText');
    
    final petrolResult = await _ocrService.parseBillText(petrolBillText, AppConstants.billTypePetrol);
    print('Parsed items: ${petrolResult.items.length}');
    for (var item in petrolResult.items) {
      print('  - ${item.name}: ${item.quantity} ltr, ₹${item.unitPrice.toStringAsFixed(2)}/ltr, Total: ₹${item.total.toStringAsFixed(2)}');
    }
    print('Total: ₹${petrolResult.total}');
    print('Date: ${petrolResult.date}');
    print('');

    // Test complex grocery bill
    final complexGroceryBill = '''
BILL NO: 12345
Date: 20/12/2024

ITEM                    QTY    RATE    AMOUNT
----------------------------------------------
Basmati Rice           2.0 kg   ₹80.00   ₹160.00
Whole Wheat Flour      1.5 kg   ₹30.00   ₹45.00
Fresh Milk             2.0 l     ₹60.00   ₹120.00
Brown Bread            3.0 pcs   ₹15.00   ₹45.00
Organic Tomatoes       1.0 kg   ₹40.00   ₹40.00
Red Onions             2.0 kg   ₹25.00   ₹50.00
Potatoes               3.0 kg   ₹20.00   ₹60.00
Cooking Oil            1.0 l    ₹150.00  ₹150.00
Sugar                  1.0 kg   ₹35.00   ₹35.00
Salt                   0.5 kg   ₹10.00   ₹5.00

SUBTOTAL: ₹710.00
GST (5%): ₹35.50
TOTAL: ₹745.50

Payment: Card
Thank you!
''';

    print('Testing Complex Grocery Bill Parsing:');
    print('Input text: $complexGroceryBill');
    
    final complexResult = await _ocrService.parseBillText(complexGroceryBill, AppConstants.billTypeGrocery);
    print('Parsed items: ${complexResult.items.length}');
    for (var item in complexResult.items) {
      print('  - ${item.name}: ${item.quantity} kg, ₹${item.unitPrice.toStringAsFixed(2)}/kg, Total: ₹${item.total.toStringAsFixed(2)}');
    }
    print('Total: ₹${complexResult.total}');
    print('Date: ${complexResult.date}');
    print('');

    print('=== OCR Test Complete ===');
  }

  static Future<void> testWithRealOCR(String extractedText, String billType) async {
    print('=== Real OCR Test ===');
    print('Bill Type: $billType');
    print('Extracted Text: $extractedText');
    
    final result = await _ocrService.parseBillText(extractedText, billType);
    print('Parsed items: ${result.items.length}');
    for (var item in result.items) {
      print('  - ${item.name}: ${item.quantity} ${item.unit}, ₹${item.unitPrice.toStringAsFixed(2)}/${item.unit}, Total: ₹${item.total.toStringAsFixed(2)}');
    }
    print('Total: ₹${result.total}');
    print('Date: ${result.date}');
    print('=== End Real OCR Test ===');
  }
}
