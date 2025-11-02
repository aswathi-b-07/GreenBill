import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Helpers {
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // Format currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format carbon value
  static String formatCarbon(double carbon) {
    return '${carbon.toStringAsFixed(2)} kg CO₂';
  }

  // Get score color
  static Color getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // Get score text
  static String getScoreText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Improvement';
  }

  // Get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return const Color(0xFFFF6B35);
      case 'food':
        return const Color(0xFF4CAF50);
      case 'packaging':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'food':
        return Icons.restaurant;
      case 'packaging':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  // Calculate percentage
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
