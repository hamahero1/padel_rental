import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

/// Shows a short toast message at the bottom of the screen (like in Lab 2).
void showMsg(String message) {
  Fluttertoast.showToast(msg: message);
}

/// 150 -> "150.00 EGP"
String money(double value) => '${value.toStringAsFixed(2)} EGP';

/// DateTime -> "15 Oct 2026"
String formatDate(DateTime? date) =>
    date == null ? '-' : DateFormat('d MMM yyyy').format(date);

/// Picks an icon from the category name, e.g. "Padel Rackets" -> racket icon.
IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('racket')) return Icons.sports_tennis;
  if (n.contains('ball')) return Icons.sports_baseball;
  if (n.contains('shoe')) return Icons.directions_run;
  if (n.contains('bag')) return Icons.backpack;
  if (n.contains('access')) return Icons.watch;
  return Icons.category;
}

/// DateTime -> "15 Oct 2026, 14:30"
String formatDateTime(DateTime? date) =>
    date == null ? '-' : DateFormat('d MMM yyyy, HH:mm').format(date);
