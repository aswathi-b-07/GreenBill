import 'package:flutter/foundation.dart';
import '../repositories/bill_repository.dart';

class BillRepositoryProvider extends ChangeNotifier {
  static final BillRepositoryProvider _instance = BillRepositoryProvider._internal();
  factory BillRepositoryProvider() => _instance;
  
  BillRepositoryProvider._internal();

  final BillRepository _repository = BillRepository();
  
  void setCurrentUser(String userId) {
    _repository.setCurrentUser(userId);
    notifyListeners();
  }

  BillRepository get repository => _repository;
}