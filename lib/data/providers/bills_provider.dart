import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/bill_report.dart';

class BillsProvider extends ChangeNotifier {
  final List<BillReport> _bills = [];
  bool _isLoading = false;

  UnmodifiableListView<BillReport> get bills => UnmodifiableListView(_bills);
  bool get isLoading => _isLoading;

  void addBill(BillReport bill) {
    _bills.add(bill);
    notifyListeners();
  }

  void removeBill(String id) {
    _bills.removeWhere((bill) => bill.id == id);
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clear() {
    _bills.clear();
    notifyListeners();
  }
}