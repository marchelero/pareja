import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/data/drinks_tasks.json');
  if (!await file.exists()) {
    print('File not found!');
    return;
  }
  
  final content = await file.readAsString();
  final List<dynamic> json = jsonDecode(content);
  int fixedCount = 0;

  for (var task in json) {
    int sips = task['sips'] ?? 0;
    String category = task['category'] ?? '';
    int intensity = task['intensity'] ?? 1;

    // Fix 0 sips
    if (sips == 0) {
      fixedCount++;
      if (category == 'challenge' || category == 'decision') {
        sips = 2; // Default base
        if (intensity >= 7) sips = 4; // High intensity
        else if (intensity >= 5) sips = 3;
      } else {
        sips = 1;
        if (intensity >= 7) sips = 3;
      }
    }

    // Cap at 4
    if (sips > 4) {
      sips = 4;
    }

    task['sips'] = sips;
  }

  await file.writeAsString(const JsonEncoder.withIndent('    ').convert(json));
  print('Fixed $fixedCount tasks.');
}
