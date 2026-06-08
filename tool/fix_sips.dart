import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  final file = File('assets/data/drinks_tasks.json');
  if (!await file.exists()) {
    debugPrint('File not found!');
    return;
  }
  
  final content = await file.readAsString();
  final List<dynamic> json = jsonDecode(content);
  int fixedCount = 0;

  for (var task in json) {
    int sips = task['sips'] ?? 0;
    String category = task['category'] ?? '';
    int intensity = task['intensity'] ?? 1;

    if (sips == 0) {
      fixedCount++;
      if (category == 'challenge' || category == 'decision') {
        sips = 2;
        if (intensity >= 7) {
          sips = 4;
        } else if (intensity >= 5) {
          sips = 3;
        }
      } else {
        sips = 1;
        if (intensity >= 7) {
          sips = 3;
        }
      }
    }

    if (sips > 4) {
      sips = 4;
    }

    task['sips'] = sips;
  }

  await file.writeAsString(const JsonEncoder.withIndent('    ').convert(json));
  debugPrint('Fixed $fixedCount tasks.');
}
